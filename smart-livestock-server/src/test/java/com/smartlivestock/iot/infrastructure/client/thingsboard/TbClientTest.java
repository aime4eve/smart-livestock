package com.smartlivestock.iot.infrastructure.client.thingsboard;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestOperations;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TbClientTest {

    @Mock
    private RestOperations rest;

    private TbClient client;

    @BeforeEach
    void setUp() {
        TbProperties properties = new TbProperties();
        properties.setPassword("secret");
        client = new TbClient(properties, new ObjectMapper(), rest);
    }

    @Test
    void shouldCacheLoginTokenAcrossCalls() {
        when(rest.postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"token\":\"t0\"}", HttpStatus.OK));
        when(rest.exchange(anyString(), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{}", HttpStatus.OK));

        client.fetchTimeseries("dev-1", 0, 1, 10);
        client.fetchTimeseries("dev-1", 0, 1, 10);

        verify(rest, times(1)).postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class));
    }

    @Test
    void shouldReloginAndReplayOn401() {
        when(rest.postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"token\":\"t0\"}", HttpStatus.OK));
        when(rest.exchange(anyString(), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenThrow(HttpClientErrorException.create(
                        HttpStatus.UNAUTHORIZED, "401", null, new byte[0], null))
                .thenReturn(new ResponseEntity<>("{\"result\":[]}", HttpStatus.OK));

        var node = client.fetchTimeseries("dev-1", 0, 1, 10);

        assertThat(node.path("result").isArray()).isTrue();
        verify(rest, times(2)).postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class));
    }

    @Test
    void shouldResolveByExactNameThroughFuzzySearch() {
        when(rest.postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"token\":\"t0\"}", HttpStatus.OK));
        // Fuzzy search returns case variants and partial matches; only the
        // exact-name match must be selected.
        when(rest.exchange(anyString(), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(
                        new ResponseEntity<>("{\"data\":[" +
                                "{\"id\":{\"id\":\"u-lower\"},\"name\":\"aabbcc\"}," +
                                "{\"id\":{\"id\":\"u-partial\"},\"name\":\"aabbccdd\"}" +
                                "]}", HttpStatus.OK),
                        new ResponseEntity<>("{\"data\":[]}", HttpStatus.OK));

        assertThat(client.resolveDeviceId("aabbcc")).isEqualTo("u-lower");
    }

    @Test
    void shouldRejectAmbiguousCaseTwins() {
        when(rest.postForEntity(contains("/api/auth/login"), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"token\":\"t0\"}", HttpStatus.OK));
        when(rest.exchange(anyString(), eq(HttpMethod.GET), any(HttpEntity.class), eq(String.class)))
                .thenReturn(new ResponseEntity<>("{\"data\":[" +
                        "{\"id\":{\"id\":\"u-lower\"},\"name\":\"aabbcc\"}," +
                        "{\"id\":{\"id\":\"u-upper\"},\"name\":\"AABBCC\"}" +
                        "]}", HttpStatus.OK));

        // resolveDeviceId("aabbcc") hits u-lower (as-is+lower dedupe) and
        // resolveDeviceId("AaBbCc") would hit both exact variants.
        assertThatThrownBy(() -> client.resolveDeviceId("aAbBcC"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Ambiguous");
    }

    @Test
    void variantsShouldDedupeSameCase() {
        assertThat(TbClient.variantsOf("aabbcc")).isEqualTo(List.of("aabbcc", "AABBCC"));
        assertThat(TbClient.variantsOf("AABBCC")).isEqualTo(List.of("AABBCC", "aabbcc"));
        assertThat(TbClient.variantsOf(null)).isEmpty();
    }
}
