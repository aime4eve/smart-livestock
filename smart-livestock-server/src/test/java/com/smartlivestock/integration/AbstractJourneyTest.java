package com.smartlivestock.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Base class for journey integration tests.
 * Provides shared Testcontainers setup, login helper, and HTTP utility methods.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public abstract class AbstractJourneyTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("smart_livestock_test");

    @Autowired
    protected TestRestTemplate restTemplate;

    @Autowired
    protected ObjectMapper objectMapper;

    // Seed data credentials
    protected String platformAdminToken;
    protected String b2bAdminToken;
    protected String ownerToken;
    protected String workerToken;

    @BeforeEach
    void baseSetUp() {
        platformAdminToken = login("13800000000", "123");
        b2bAdminToken = login("13900139000", "123");
        ownerToken = login("13800138000", "123");
        workerToken = login("13800138001", "123");
    }

    // --- Auth helpers ---

    @SuppressWarnings("unchecked")
    protected String login(String phone, String password) {
        Map<String, String> body = Map.of("phone", phone, "password", password);
        ResponseEntity<Map> resp = restTemplate.postForEntity("/api/v1/auth/login", body, Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) resp.getBody().get("data");
        return (String) data.get("accessToken");
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> loginRaw(String phone, String password) {
        Map<String, String> body = Map.of("phone", phone, "password", password);
        return restTemplate.postForEntity("/api/v1/auth/login", body, Map.class);
    }

    // --- HTTP helpers ---

    protected HttpHeaders authHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        return headers;
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> getApi(String token, String path) {
        HttpHeaders headers = authHeaders(token);
        ResponseEntity<Map> resp = restTemplate.exchange(
                path, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (Map<String, Object>) resp.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> getRaw(String token, String path) {
        HttpHeaders headers = authHeaders(token);
        return restTemplate.exchange(
                path, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> getRawNoAuth(String path) {
        return restTemplate.getForEntity(path, Map.class);
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> postApi(String token, String path, Object body) {
        HttpHeaders headers = authHeaders(token);
        ResponseEntity<Map> resp = restTemplate.exchange(
                path, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (Map<String, Object>) resp.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> postRaw(String token, String path, Object body) {
        HttpHeaders headers = authHeaders(token);
        return restTemplate.exchange(
                path, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> postRawNoAuth(String path, Object body) {
        return restTemplate.postForEntity(path, body, Map.class);
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> putApi(String token, String path, Object body) {
        HttpHeaders headers = authHeaders(token);
        ResponseEntity<Map> resp = restTemplate.exchange(
                path, HttpMethod.PUT, new HttpEntity<>(body, headers), Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (Map<String, Object>) resp.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> putRaw(String token, String path, Object body) {
        HttpHeaders headers = authHeaders(token);
        return restTemplate.exchange(
                path, HttpMethod.PUT, new HttpEntity<>(body, headers), Map.class);
    }

    @SuppressWarnings("unchecked")
    protected Map<String, Object> deleteApi(String token, String path) {
        HttpHeaders headers = authHeaders(token);
        ResponseEntity<Map> resp = restTemplate.exchange(
                path, HttpMethod.DELETE, new HttpEntity<>(headers), Map.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (Map<String, Object>) resp.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    protected ResponseEntity<Map> deleteRaw(String token, String path) {
        HttpHeaders headers = authHeaders(token);
        return restTemplate.exchange(
                path, HttpMethod.DELETE, new HttpEntity<>(headers), Map.class);
    }

    // --- Assertion helpers ---

    protected void assertOk(ResponseEntity<Map> resp) {
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).isNotNull();
        assertThat(resp.getBody().get("code")).isEqualTo("OK");
    }

    protected void assertCreated(ResponseEntity<Map> resp) {
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(resp.getBody()).isNotNull();
        assertThat(resp.getBody().get("code")).isEqualTo("OK");
    }

    protected void assertError(ResponseEntity<Map> resp, HttpStatus status, String errorCode) {
        assertThat(resp.getStatusCode()).isEqualTo(status);
        assertThat(resp.getBody()).isNotNull();
        assertThat(resp.getBody().get("code")).isEqualTo(errorCode);
    }

    // --- Data helpers ---

    @SuppressWarnings("unchecked")
    protected List<Map<String, Object>> getItems(Map<String, Object> data) {
        return (List<Map<String, Object>>) data.get("items");
    }
}
