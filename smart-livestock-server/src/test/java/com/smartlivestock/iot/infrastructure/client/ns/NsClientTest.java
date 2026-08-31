package com.smartlivestock.iot.infrastructure.client.ns;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatchers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestOperations;

import java.net.URI;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NsClientTest {

    @Mock
    private RestOperations rest;

    private NsProperties properties;
    private NsClient client;

    @BeforeEach
    void setUp() {
        properties = new NsProperties();
        properties.setEnabled(true);
        properties.setUsername("ns-user");
        properties.setPassword("secret");
        properties.setPageSize(1);
        client = new NsClient(properties, new ObjectMapper(), rest);
    }

    @Test
    void shouldPageDevicesAndUseXToken() {
        when(rest.postForEntity(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"code\":0,\"data\":{\"token\":\"token-1\"}}",
                        HttpStatus.OK));
        when(rest.exchange(any(URI.class), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(
                        new ResponseEntity<>("{\"code\":0,\"count\":2,\"data\":[{\"dev_eui\":\"A\",\"project\":89,\"app\":18}]}",
                                HttpStatus.OK),
                        new ResponseEntity<>("{\"code\":0,\"count\":2,\"data\":[{\"devEui\":\"B\"}]}",
                                HttpStatus.OK));

        var devices = client.listDevices(89);

        assertThat(devices).hasSize(2);
        assertThat(devices.get(0).projectId()).isEqualTo(89);
        assertThat(devices.get(0).appId()).isEqualTo(18);
        assertThat(devices.get(1).eui()).isEqualTo("B");
        verify(rest).postForEntity(
                eq(properties.getBaseUrl() + "/backend/api/login/"),
                ArgumentMatchers.<HttpEntity<String>>argThat(entity ->
                        entity.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE) != null),
                eq(String.class));
        ArgumentCaptor<HttpEntity> requests = ArgumentCaptor.forClass(HttpEntity.class);
        ArgumentCaptor<URI> uris = ArgumentCaptor.forClass(URI.class);
        verify(rest, times(2)).exchange(uris.capture(), eq(HttpMethod.GET), requests.capture(),
                eq(String.class));
        assertThat(uris.getAllValues())
                .allSatisfy(uri -> assertThat(uri.getPath())
                        .isEqualTo("/backend/org_api/lora_wan/device/list/"));
        assertThat(requests.getAllValues())
                .allSatisfy(request -> assertThat(request.getHeaders().get("x-token"))
                        .containsExactly("token-1"));
    }

    @Test
    void shouldQuerySingleDeviceByEui() {
        when(rest.postForEntity(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"code\":0,\"data\":{\"token\":\"token-1\"}}",
                        HttpStatus.OK));
        when(rest.exchange(any(URI.class), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"code\":0,\"count\":1,\"data\":[{\"dev_eui\":\"a\"}]}",
                        HttpStatus.OK));

        assertThat(client.findDeviceByEui("a")).contains(new NsClient.NsDevice("a", 0, 0, null));
    }

    @Test
    void shouldRejectNonSuccessEnvelope() {
        when(rest.postForEntity(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"code\":0,\"data\":{\"token\":\"token-1\"}}",
                        HttpStatus.OK));
        when(rest.exchange(any(URI.class), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"code\":1,\"msg\":\"请先登录\"}", HttpStatus.OK));

        assertThatThrownBy(() -> client.listDevices(89))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("NS device list failed");
    }

    @Test
    void shouldRequireEnabledFlag() {
        properties.setEnabled(false);
        assertThatThrownBy(() -> client.listDevices(89))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("disabled");
    }

    @Test
    void enabledClientShouldRequireCredentials() {
        properties.setEnabled(true);
        properties.setUsername("ns-user");
        properties.setPassword("");
        assertThatThrownBy(properties::validateCredentials)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("smartlivestock.ns.enabled=true");
    }
}
