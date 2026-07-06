package com.ai.openapi.auth.context;

import lombok.Data;

@Data
public class RequestContext {

    private Long appId;
    private String appExternalId;
    private Long keyId;
    private String keyExternalId;
    private String scope;
    private String clientIp;
    private String internalUserId;

    private static final ThreadLocal<RequestContext> CONTEXT = new ThreadLocal<>();

    public static void set(RequestContext context) {
        CONTEXT.set(context);
    }

    public static RequestContext get() {
        return CONTEXT.get();
    }

    public static void clear() {
        CONTEXT.remove();
    }
}
