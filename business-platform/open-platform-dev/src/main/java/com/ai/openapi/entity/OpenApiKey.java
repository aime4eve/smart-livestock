package com.ai.openapi.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@TableName("open_api_key")
public class OpenApiKey {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long appId;

    private String keyId;

    private String apiKeyHash;

    private String description;

    private String scope;

    private String status;

    private OffsetDateTime expiresAt;

    private OffsetDateTime lastUsedAt;

    private Long internalUserId;

    @TableField(fill = FieldFill.INSERT)
    private OffsetDateTime createdAt;

    private OffsetDateTime rotatedAt;
}
