package com.ai.openapi.key.controller;

import com.ai.openapi.common.response.OpenApiResponse;
import com.ai.openapi.key.dto.*;
import com.ai.openapi.key.service.ApiKeyService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@Validated
@RestController
@RequestMapping("/v1/api-keys")
public class ApiKeyController {

    private final ApiKeyService apiKeyService;

    public ApiKeyController(ApiKeyService apiKeyService) {
        this.apiKeyService = apiKeyService;
    }

    @PostMapping
    public ResponseEntity<CreateKeyResponse> createKey(@Valid @RequestBody CreateKeyRequest request) {
        CreateKeyResponse response = apiKeyService.createKey(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<OpenApiResponse<KeyInfoVO>> listKeys(
            @RequestParam(defaultValue = "1") @Min(1) @Max(1_000_000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int pageSize) {
        OpenApiResponse<KeyInfoVO> response = apiKeyService.listKeys(page, pageSize);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{key_id}")
    public ResponseEntity<RevokeKeyResponse> revokeKey(@PathVariable("key_id") String keyId) {
        RevokeKeyResponse response = apiKeyService.revokeKey(keyId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{key_id}/rotate")
    public ResponseEntity<RotateKeyResponse> rotateKey(@PathVariable("key_id") String keyId) {
        RotateKeyResponse response = apiKeyService.rotateKey(keyId);
        return ResponseEntity.ok(response);
    }
}
