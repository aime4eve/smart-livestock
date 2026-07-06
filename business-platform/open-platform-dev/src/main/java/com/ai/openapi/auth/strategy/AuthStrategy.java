package com.ai.openapi.auth.strategy;

import jakarta.servlet.http.HttpServletRequest;

public interface AuthStrategy {

    void authenticate(HttpServletRequest request);
}
