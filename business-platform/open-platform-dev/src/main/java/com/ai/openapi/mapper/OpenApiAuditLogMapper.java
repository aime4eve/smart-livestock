package com.ai.openapi.mapper;

import com.ai.openapi.entity.OpenApiAuditLog;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface OpenApiAuditLogMapper extends BaseMapper<OpenApiAuditLog> {
}
