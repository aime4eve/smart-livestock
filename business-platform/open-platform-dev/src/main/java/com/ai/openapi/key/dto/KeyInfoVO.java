package com.ai.openapi.key.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class KeyInfoVO {

    private String key_id;
    private String description;
    private String scope;
    private String status;
    private OffsetDateTime expires_at;
    private OffsetDateTime last_used_at;
    private OffsetDateTime created_at;
}
