package com.smartlivestock.platform.messaging.push;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * NIX-430: APNs push configuration. Android (FCM) is deferred — the token
 * schema and dispatch pipeline are platform-agnostic already.
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.push.apns")
public class PushProperties {

    /** Master switch; env override per environment (dev/test/prod). */
    private boolean enabled = false;

    /** Path to the APNs signing key (.p8) on the server filesystem — never in the repo. */
    private String keyPath;

    /**
     * The .p8 key as a single-line base64 of the whole file — the deployment
     * seam for environments where no host path can be bind-mounted into the
     * container (the .env file lives server-side only). Takes precedence
     * over {@link #keyPath} when set.
     */
    private String keyBase64;

    private String keyId;

    private String teamId;

    /** APNs topic = the iOS app bundle id. */
    private String topic = "com.hktlora.smartlivestock";

    /** sandbox (dev-signed installs) | production (TestFlight / App Store). */
    private String environment = "sandbox";

    /** Locale used to localize alert text for push bodies. */
    private String locale = "zh";

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public String getKeyPath() { return keyPath; }
    public void setKeyPath(String keyPath) { this.keyPath = keyPath; }
    public String getKeyBase64() { return keyBase64; }
    public void setKeyBase64(String keyBase64) { this.keyBase64 = keyBase64; }
    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }
    public String getTeamId() { return teamId; }
    public void setTeamId(String teamId) { this.teamId = teamId; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getEnvironment() { return environment; }
    public void setEnvironment(String environment) { this.environment = environment; }
    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }
}
