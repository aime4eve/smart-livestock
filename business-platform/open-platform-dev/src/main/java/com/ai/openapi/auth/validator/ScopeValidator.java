package com.ai.openapi.auth.validator;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

@Component
public class ScopeValidator {

    private final Map<String, Set<String>> scopePermissions = Map.of(
            "read", Set.of("GET"),
            "write", Set.of("POST", "PUT"),
            "read_write", Set.of("GET", "POST", "PUT"),
            "admin", Set.of("GET", "POST", "PUT", "DELETE")
    );

    public boolean isAllowed(String scope, String httpMethod) {
        if (scope == null || httpMethod == null) {
            return false;
        }
        Set<String> allowed = scopePermissions.get(scope);
        return allowed != null && allowed.contains(httpMethod.toUpperCase());
    }
}
