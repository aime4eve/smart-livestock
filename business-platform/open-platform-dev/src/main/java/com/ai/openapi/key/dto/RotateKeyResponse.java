package com.ai.openapi.key.dto;

import lombok.Data;

import java.time.OffsetDateTime;

@Data
public class RotateKeyResponse {

    private String key_id;
    private String new_api_key;
    private OffsetDateTime rotated_at;
}
