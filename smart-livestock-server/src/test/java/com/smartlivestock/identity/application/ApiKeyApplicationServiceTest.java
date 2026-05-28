package com.smartlivestock.identity.application;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.identity.domain.repository.ApiKeyRepository;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ApiKeyApplicationServiceTest {

    @Mock private ApiKeyRepository apiKeyRepository;

    @Test
    void createApiKey_returnsSkLivePrefix() {
        when(apiKeyRepository.save(any())).thenAnswer(inv -> {
            ApiKey k = inv.getArgument(0);
            k.setId(1L);
            return k;
        });

        ApiKeyApplicationService svc = new ApiKeyApplicationService(apiKeyRepository);
        Map<String, Object> result = svc.createApiKey(1L, "test-key", "admin");

        String rawKey = (String) result.get("rawKey");
        assertTrue(rawKey.startsWith("sk_live_"));
        assertTrue(((String) result.get("prefix")).startsWith("sk_live_"));
        assertEquals("test-key", result.get("keyName"));
    }

    @Test
    void validateApiKey_succeedsWithCorrectKey() {
        when(apiKeyRepository.save(any())).thenAnswer(inv -> {
            ApiKey k = inv.getArgument(0);
            k.setId(1L);
            return k;
        });

        ApiKeyApplicationService svc = new ApiKeyApplicationService(apiKeyRepository);

        Map<String, Object> created = svc.createApiKey(1L, "test", "admin");
        String rawKey = (String) created.get("rawKey");

        ApiKey stored = new ApiKey();
        stored.setId(1L);
        stored.setStatus("ACTIVE");
        stored.setRole("admin");

        when(apiKeyRepository.findByKeyHash(anyString())).thenReturn(Optional.of(stored));

        ApiKey validated = svc.validateApiKey(rawKey);
        assertNotNull(validated);
        verify(apiKeyRepository).save(argThat(k -> k.getLastUsedAt() != null));
    }

    @Test
    void revokeApiKey_setsRevoked() {
        ApiKey apiKey = new ApiKey();
        apiKey.setId(1L);
        apiKey.setStatus("ACTIVE");
        when(apiKeyRepository.findById(1L)).thenReturn(Optional.of(apiKey));
        when(apiKeyRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ApiKeyApplicationService svc = new ApiKeyApplicationService(apiKeyRepository);
        svc.revokeApiKey(1L);

        verify(apiKeyRepository).save(argThat(k -> "REVOKED".equals(k.getStatus())));
    }

    @Test
    void deleteApiKey_rejectsActiveKey() {
        ApiKey apiKey = new ApiKey();
        apiKey.setId(1L);
        apiKey.setStatus("ACTIVE");
        when(apiKeyRepository.findById(1L)).thenReturn(Optional.of(apiKey));

        ApiKeyApplicationService svc = new ApiKeyApplicationService(apiKeyRepository);
        assertThrows(ApiException.class, () -> svc.deleteApiKey(1L));
    }
}
