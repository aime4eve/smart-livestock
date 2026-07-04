package com.ai.openapi.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@TableName("open_api_audit_log")
public class OpenApiAuditLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long appId;

    private Long keyId;

    private String httpMethod;

    private String requestPath;

    private Short responseStatus;

    private String clientIp;

    private Integer requestDuration;

    @TableField(fill = FieldFill.INSERT)
    private OffsetDateTime createdAt;
}
