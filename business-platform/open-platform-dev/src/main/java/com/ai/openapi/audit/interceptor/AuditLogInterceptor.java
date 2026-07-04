package com.ai.openapi.audit.interceptor;

import com.ai.openapi.audit.event.AuditEvent;
import com.ai.openapi.audit.service.AuditLogService;
import com.ai.openapi.auth.context.RequestContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Slf4j
@Component
public class AuditLogInterceptor implements HandlerInterceptor {

    private final AuditLogService auditLogService;

    public AuditLogInterceptor(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        try {
            RequestContext ctx = RequestContext.get();
            if (ctx == null) {
                return;
            }

            AuditEvent event = new AuditEvent();
            event.setAppId(ctx.getAppId());
            event.setKeyId(ctx.getKeyId());
            event.setHttpMethod(request.getMethod());
            event.setRequestPath(request.getRequestURI());
            event.setResponseStatus((short) response.getStatus());
            event.setClientIp(ctx.getClientIp());
            event.setRequestDuration(0);

            auditLogService.recordAsync(event);
        } catch (Exception e) {
            log.warn("审计日志记录异常: {}", e.getMessage());
        }
    }
}
