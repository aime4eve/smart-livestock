package com.smartlivestock.shared.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;
import org.yaml.snakeyaml.Yaml;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Pulls blade integration addresses from the shared Nacos (HTTP v1 API) at
 * startup, so a blade-side address change is a console edit plus an app
 * restart instead of an ssh + sed round on the deploy host.
 *
 * <p>Uses the HTTP API (8848) on purpose: the official nacos-config starter
 * needs the gRPC ports (9848/9849), which are not reachable from the deploy
 * host, and this project deliberately avoids a runtime Nacos client
 * dependency. Zero extra dependencies — RestTemplate, Jackson and snakeyaml
 * are already on the classpath.</p>
 *
 * <p>Optional by design: any failure (network, auth, missing dataId, parse)
 * skips loading and the app boots with local defaults. Enabled only via
 * {@code NACOS_CONFIG_ENABLED=true} in dev/test env files; release/ONPREM
 * images never set it and behave exactly as before.</p>
 *
 * <p>Property precedence: the loaded source is inserted right after the
 * system environment, so OS env vars still win (emergency override), while
 * Nacos values override application.yml defaults.</p>
 *
 * <p>Runs before the logging system is initialized, so regular log calls
 * would be swallowed — the outcome is published via the
 * {@code smartlivestock.nacos.config.outcome} system property and reported
 * by {@link NacosRemoteConfigReporter} once logging is up.</p>
 */
public class NacosRemoteConfigLoader implements EnvironmentPostProcessor {

    static final String SOURCE_NAME = "nacosRemoteConfig";
    static final String OUTCOME_PROPERTY = "smartlivestock.nacos.config.outcome";

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (!environment.getProperty("nacos.config.enabled", Boolean.class, false)) {
            return;
        }
        String serverAddr = environment.getProperty("nacos.config.server-addr", "");
        String namespace = environment.getProperty("nacos.config.namespace", "");
        String dataId = environment.getProperty("nacos.config.data-id", "");
        String group = environment.getProperty("nacos.config.group", "DEFAULT_GROUP");
        String username = environment.getProperty("nacos.config.username", "");
        String password = environment.getProperty("nacos.config.password", "");
        if (!StringUtils.hasText(serverAddr) || !StringUtils.hasText(dataId)) {
            System.setProperty(OUTCOME_PROPERTY, "skipped: server-addr/data-id missing");
            return;
        }
        try {
            String accessToken = login(serverAddr, username, password);
            String content = fetchConfig(serverAddr, namespace, group, dataId, accessToken);
            Map<String, Object> flat = new LinkedHashMap<>();
            flatten("", new Yaml().load(content), flat);
            if (flat.isEmpty()) {
                System.setProperty(OUTCOME_PROPERTY, "skipped: dataId=" + dataId + " content empty");
                return;
            }
            MapPropertySource source = new MapPropertySource(SOURCE_NAME, flat);
            MutablePropertySources sources = environment.getPropertySources();
            if (sources.contains(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME)) {
                sources.addAfter(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME, source);
            } else {
                sources.addFirst(source);
            }
            System.setProperty(OUTCOME_PROPERTY, "loaded dataId=" + dataId + " keys=" + flat.keySet());
        } catch (Exception e) {
            System.setProperty(OUTCOME_PROPERTY, "unavailable (" + e.getMessage() + "), using local defaults");
        }
    }

    private String login(String serverAddr, String username, String password) throws Exception {
        if (!StringUtils.hasText(username)) {
            return "";
        }
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("username", username);
        form.add("password", password);
        String body = restTemplate.postForObject(
                serverAddr + "/nacos/v1/auth/login", new HttpEntity<>(form, headers), String.class);
        String token = objectMapper.readTree(body).path("accessToken").asText("");
        if (!StringUtils.hasText(token)) {
            throw new IllegalStateException("no accessToken in nacos login response");
        }
        return token;
    }

    private String fetchConfig(String serverAddr, String namespace, String group,
                               String dataId, String accessToken) {
        StringBuilder url = new StringBuilder(serverAddr)
                .append("/nacos/v1/cs/configs?dataId=").append(urlEncode(dataId))
                .append("&group=").append(urlEncode(group));
        if (StringUtils.hasText(namespace)) {
            url.append("&tenant=").append(urlEncode(namespace));
        }
        if (StringUtils.hasText(accessToken)) {
            url.append("&accessToken=").append(urlEncode(accessToken));
        }
        String content = restTemplate.getForObject(url.toString(), String.class);
        if (!StringUtils.hasText(content)) {
            throw new IllegalStateException("config content empty (dataId may not exist)");
        }
        return content;
    }

    @SuppressWarnings("unchecked")
    private void flatten(String prefix, Object node, Map<String, Object> out) {
        if (node instanceof Map<?, ?> map) {
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                String key = prefix.isEmpty() ? String.valueOf(entry.getKey()) : prefix + "." + entry.getKey();
                flatten(key, entry.getValue(), out);
            }
        } else if (node != null) {
            out.put(prefix, node);
        }
    }

    private String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
