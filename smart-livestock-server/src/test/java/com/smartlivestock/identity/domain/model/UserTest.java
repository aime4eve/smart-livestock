package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class UserTest {

    @Test
    void shouldCreateUserWithRequiredFields() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        assertThat(user.getUsername()).isEqualTo("zhangsan");
        assertThat(user.getName()).isEqualTo("张三");
        assertThat(user.getRole()).isEqualTo(Role.OWNER);
        assertThat(user.getTenantId()).isEqualTo(1L);
        assertThat(user.isActive()).isTrue();
    }

    @Test
    void shouldNotActivateInactiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThatThrownBy(user::activate)
            .isInstanceOf(ApiException.class)
            .extracting(e -> ((ApiException) e).getCode())
            .isEqualTo(ErrorCode.BAD_REQUEST);
    }

    @Test
    void shouldDeactivateActiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThat(user.isActive()).isFalse();
    }

    @Test
    void shouldNotDeactivateInactiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThatThrownBy(user::deactivate)
            .isInstanceOf(ApiException.class);
    }

    @Test
    void shouldRecordLastLogin() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        assertThat(user.getLastLoginAt()).isNull();
        user.recordLogin();
        assertThat(user.getLastLoginAt()).isNotNull();
    }

    @Test
    void shouldCheckRole() {
        User owner = new User("a", "p", "n", Role.OWNER, 1L);
        User worker = new User("b", "p", "n", Role.WORKER, 1L);
        assertThat(owner.isOwner()).isTrue();
        assertThat(worker.isOwner()).isFalse();
        assertThat(worker.isWorker()).isTrue();
    }

    @Test
    void shouldHavePlatformAdminWithNullTenant() {
        User admin = new User("admin", "p", "平台管理员", Role.PLATFORM_ADMIN, null);
        assertThat(admin.getTenantId()).isNull();
        assertThat(admin.getRole()).isEqualTo(Role.PLATFORM_ADMIN);
    }
}
