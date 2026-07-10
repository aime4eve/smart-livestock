package com.ai.openapi.key.dto;

import lombok.Data;

@Data
public class RevokeKeyResponse {

    private String key_id;
    private String status;
}
