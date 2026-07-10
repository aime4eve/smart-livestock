package com.ai.openapi.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@TableName("open_app")
public class OpenApp {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String appId;

    private String appSecretHash;

    private String name;

    private String description;

    private String status;
    private String internalUserId;

    @TableField(fill = FieldFill.INSERT)
    private OffsetDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private OffsetDateTime updatedAt;
}
