package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import lombok.Data;

@Data
public class LoginUser {
    private String userId;
    private String userName;
    private String tenantId;

    public static LoginUser from(String userId, String tenantId) {
        LoginUser user = new LoginUser();
        user.setUserId(userId);
        user.setTenantId(tenantId);
        return user;
    }
}
