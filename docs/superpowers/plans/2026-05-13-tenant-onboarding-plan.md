# 租户入驻流程实施计划 — Phase 1

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐"管理员开通 → owner 首次登录 → 创建牧场 → 设备/牲畜绑定"的端到端入驻流程，使 owner 无预置数据也能完成自助闭环。

**Architecture:** 后端在现有 FarmApplicationService 上叠加"创建牧场时自动写 user_farm_assignments"逻辑，DashboardController 补充真实设备统计。前端新建 FarmCreationWizardPage 三步向导，DashboardPage 增加空状态引导，ApiCache 补充 createFarm/createInstallation 方法。

**Tech Stack:** Spring Boot 3.x / Java 17 (后端)，Flutter / Riverpod / flutter_map (前端)

**Spec:** `docs/superpowers/specs/2026-05-13-tenant-onboarding-design.md`

**前置依赖:** MVP Phase 1 Task 1-14 已全部完成

---

## Issue 索引表

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #40 | 构建 MVP（入驻流程子任务） |

## 完成记录表

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| | | | |

---

## 文件结构总览

### 后端（新建 2 文件，修改 3 文件）

```
smart-livestock-server/src/main/java/com/smartlivestock/
├── identity/
│   ├── domain/repository/
│   │   └── UserFarmAssignmentRepository.java    ← 新建（port 接口）
│   ├── application/
│   │   └── FarmApplicationService.java          ← 修改（加自动关联）
│   ├── infrastructure/persistence/
│   │   └── JpaUserFarmAssignmentRepositoryImpl.java  ← 新建（adapter）
│   └── interfaces/
│       └── FarmController.java                  ← 修改（传 userId + role 校验）
├── ranch/interfaces/
│   └── DashboardController.java                 ← 修改（onlineDeviceCount 真实计算）
└── test/
    └── identity/application/
        └── FarmApplicationServiceTest.java      ← 修改（加自动关联测试）
```

### 前端（新建 5 文件，修改 4 文件）

```
Mobile/mobile_app/lib/
├── core/api/
│   └── api_cache.dart                           ← 修改（加 createFarm / createInstallation）
├── features/
│   ├── dashboard/presentation/
│   │   └── dashboard_page.dart                  ← 修改（加空状态分支）
│   ├── farm_switcher/
│   │   └── farm_switcher_controller.dart        ← 修改（mock 空牧场分支）
│   └── farm_creation/                           ← 新建目录
│       ├── presentation/
│       │   ├── farm_creation_wizard_page.dart   ← 新建（向导容器）
│       │   ├── wizard_step_basic_info.dart      ← 新建（Step 1）
│       │   ├── wizard_step_fence_drawing.dart   ← 新建（Step 2）
│       │   ├── wizard_step_complete.dart        ← 新建（Step 3）
│       │   └── draft_polygon_editor.dart        ← 新建（草稿围栏编辑器）
│       └── domain/
│           └── draft_fence_state.dart           ← 新建（草稿围栏状态模型）
```

---

## Task 1: UserFarmAssignment Domain Repository + Adapter

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/repository/UserFarmAssignmentRepository.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/identity/infrastructure/persistence/SpringDataUserFarmAssignmentRepository.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/identity/infrastructure/persistence/JpaUserFarmAssignmentRepositoryImpl.java`

- [ ] **Step 1: 创建 domain 层 Repository 接口**

`identity/domain/repository/UserFarmAssignmentRepository.java`:
```java
package com.smartlivestock.identity.domain.repository;

import java.util.Optional;

public interface UserFarmAssignmentRepository {
    boolean existsByUserIdAndFarmId(Long userId, Long farmId);
    void save(Long userId, Long farmId, String role, String status);
}
```

遵循 FarmRepository/UserRepository 同一风格（port 接口，纯业务方法）。

- [ ] **Step 2: 扩展 SpringDataUserFarmAssignmentRepository**

在 `SpringDataUserFarmAssignmentRepository.java` 中添加查询方法：
```java
boolean existsByUserIdAndFarmId(Long userId, Long farmId);
```

- [ ] **Step 3: 创建 Adapter 实现**

`identity/infrastructure/persistence/JpaUserFarmAssignmentRepositoryImpl.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class JpaUserFarmAssignmentRepositoryImpl implements UserFarmAssignmentRepository {

    private final SpringDataUserFarmAssignmentRepository springDataRepo;

    @Override
    public boolean existsByUserIdAndFarmId(Long userId, Long farmId) {
        return springDataRepo.existsByUserIdAndFarmId(userId, farmId);
    }

    @Override
    public void save(Long userId, Long farmId, String role, String status) {
        UserFarmAssignmentJpaEntity entity = new UserFarmAssignmentJpaEntity();
        entity.setUserId(userId);
        entity.setFarmId(farmId);
        entity.setRole(role);
        entity.setStatus(status);
        springDataRepo.save(entity);
    }
}
```

- [ ] **Step 4: 验证编译**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/identity/
git commit -m "feat(identity): add UserFarmAssignmentRepository port + JPA adapter"
```

---

## Task 2: FarmApplicationService 自动关联 owner

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/identity/application/FarmApplicationService.java`
- Create: `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java`

- [ ] **Step 1: 写失败测试**

`src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java`:
```java
package com.smartlivestock.identity.application.service;

import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmApplicationServiceTest {

    @Mock private FarmRepository farmRepository;
    @Mock private UserRepository userRepository;
    @Mock private UserFarmAssignmentRepository assignmentRepository;

    @InjectMocks private FarmApplicationService farmApplicationService;

    @Test
    void shouldAutoAssignOwnerWhenCreatingFarm() {
        User owner = new User("owner", "hash", "牧场主", Role.OWNER, 1L);
        when(userRepository.findById(100L)).thenReturn(Optional.of(owner));
        when(farmRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(assignmentRepository.existsByUserIdAndFarmId(eq(100L), anyLong())).thenReturn(false);

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", new BigDecimal("28.2458"), new BigDecimal("112.8519"), new BigDecimal("500"));

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 100L);

        assertThat(result).isNotNull();
        verify(assignmentRepository).save(eq(100L), anyLong(), eq("OWNER"), eq("ACTIVE"));
    }

    @Test
    void shouldSkipAssignmentWhenUserIdIsNull() {
        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);
        when(farmRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FarmDto result = farmApplicationService.createFarm(1L, cmd, null);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }

    @Test
    void shouldSkipAssignmentWhenNotOwner() {
        User worker = new User("worker", "hash", "牧工", Role.WORKER, 1L);
        when(userRepository.findById(200L)).thenReturn(Optional.of(worker));
        when(farmRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 200L);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }

    @Test
    void shouldSkipAssignmentWhenAlreadyAssigned() {
        User owner = new User("owner", "hash", "牧场主", Role.OWNER, 1L);
        when(userRepository.findById(100L)).thenReturn(Optional.of(owner));
        when(farmRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(assignmentRepository.existsByUserIdAndFarmId(eq(100L), anyLong())).thenReturn(true);

        CreateFarmCommand cmd = new CreateFarmCommand("新牧场", null, null, null);

        FarmDto result = farmApplicationService.createFarm(1L, cmd, 100L);

        assertThat(result).isNotNull();
        verify(assignmentRepository, never()).save(anyLong(), anyLong(), anyString(), anyString());
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd smart-livestock-server && ./gradlew test --tests "FarmApplicationServiceTest"`
Expected: FAIL（createFarm 签名不匹配）

- [ ] **Step 3: 修改 FarmApplicationService**

`identity/application/FarmApplicationService.java`:
```java
@Service
@RequiredArgsConstructor
public class FarmApplicationService {

    private final FarmRepository farmRepository;
    private final UserRepository userRepository;
    private final UserFarmAssignmentRepository assignmentRepository;

    @Transactional
    public FarmDto createFarm(Long tenantId, CreateFarmCommand command, Long userId) {
        Farm farm = new Farm(tenantId, command.name(), command.latitude(), command.longitude(), command.areaHectares());
        Farm saved = farmRepository.save(farm);

        if (userId != null) {
            autoAssignOwner(userId, saved.getId(), tenantId);
        }

        return FarmDto.from(saved);
    }

    private void autoAssignOwner(Long userId, Long farmId, Long tenantId) {
        var userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return;

        var user = userOpt.get();
        if (!user.isOwner()) return;
        if (!tenantId.equals(user.getTenantId())) return;
        if (assignmentRepository.existsByUserIdAndFarmId(userId, farmId)) return;

        assignmentRepository.save(userId, farmId, "OWNER", "ACTIVE");
    }

    @Transactional(readOnly = true)
    public FarmDto getFarm(Long id) {
        Farm farm = farmRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + id));
        return FarmDto.from(farm);
    }

    @Transactional(readOnly = true)
    public List<FarmDto> listFarms(Long tenantId) {
        return farmRepository.findByTenantId(tenantId).stream()
                .map(FarmDto::from)
                .toList();
    }

    @Transactional
    public void deleteFarm(Long id) {
        if (farmRepository.findById(id).isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + id);
        }
        farmRepository.deleteById(id);
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd smart-livestock-server && ./gradlew test --tests "FarmApplicationServiceTest"`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/identity/application/FarmApplicationService.java smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java
git commit -m "feat(identity): auto-assign owner to farm on creation — TDD"
```

---

## Task 3: FarmController 传 userId

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/FarmController.java`

- [ ] **Step 1: 修改 FarmController.createFarm**

在 `FarmController.createFarm` 方法中从 SecurityContext 取 userId 传入 Service：

```java
@PostMapping("/farms")
public ResponseEntity<ApiResponse<FarmDto>> createFarm(@RequestBody Map<String, Object> body) {
    Long tenantId = TenantContext.getCurrentTenant();
    Long userId = getCurrentUserId();
    CreateFarmCommand command = new CreateFarmCommand(
            (String) body.get("name"),
            toBigDecimal(body.get("latitude")),
            toBigDecimal(body.get("longitude")),
            toBigDecimal(body.get("areaHectares"))
    );
    FarmDto farm = farmApplicationService.createFarm(tenantId, command, userId);
    return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(farm));
}

private Long getCurrentUserId() {
    var auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || auth.getPrincipal() == null) return null;
    try {
        return Long.valueOf(auth.getPrincipal().toString());
    } catch (NumberFormatException e) {
        return null;
    }
}
```

需要 import `org.springframework.security.core.context.SecurityContextHolder`。

Admin 侧 `FarmAdminController`（如有 createFarm）传 null 作为 userId，不触发自动关联。

- [ ] **Step 2: 修复其他调用 createFarm 的地方**

搜索所有 `createFarm(` 调用点，更新签名（新增 userId 参数）。Admin 端点传 null。

- [ ] **Step 3: 验证编译 + 运行全量测试**

Run: `cd smart-livestock-server && ./gradlew test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/
git commit -m "feat(identity): pass userId from JWT to FarmApplicationService for auto-assignment"
```

---

## Task 4: DashboardController onlineDeviceCount 真实计算

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/DashboardController.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/repository/DeviceRepository.java`（添加 countActiveByTenant）
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/service/DeviceApplicationService.java`（添加 countActiveByFarm 方法）

- [ ] **Step 1: 在 DeviceRepository 添加统计方法**

`iot/domain/repository/DeviceRepository.java` 添加：
```java
long countByTenantIdAndStatus(Long tenantId, String status);
```

在 SpringData 实现中添加对应方法。

- [ ] **Step 2: 在 DeviceApplicationService 添加 countActiveByFarm**

```java
@Transactional(readOnly = true)
public long countActiveByFarm(Long farmId) {
    Long tenantId = TenantContext.getCurrentTenant();
    return deviceRepository.countByTenantIdAndStatus(tenantId, "ACTIVE");
}
```

- [ ] **Step 3: 修改 DashboardController 注入 DeviceApplicationService**

```java
private final DeviceApplicationService deviceApplicationService;

// 在 summary 方法中替换 onlineDeviceCount 的硬编码 0：
long onlineDeviceCount = deviceApplicationService.countActiveByFarm(farmId);
```

- [ ] **Step 4: 验证编译 + 测试**

Run: `cd smart-livestock-server && ./gradlew compileJava && ./gradlew test`
Expected: BUILD SUCCESSFUL / ALL PASS

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/ smart-livestock-server/src/main/java/com/smartlivestock/iot/
git commit -m "feat(ranch): compute onlineDeviceCount from real device data in dashboard"
```

---

## Task 5: Flutter ApiCache — createFarm + createInstallation

**Files:**
- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`

- [ ] **Step 1: 添加 createFarmRemote 方法**

在 ApiCache 中添加 createFarmRemote 方法，POST `/farms`，成功后调用 `fetchFarms` 刷新牧场列表。

- [ ] **Step 2: 添加 createInstallationRemote 方法**

在 ApiCache 中添加 createInstallationRemote 方法，POST `/farms/{farmId}/installations`。

- [ ] **Step 3: 运行现有测试确认无回归**

Run: `cd Mobile/mobile_app && flutter test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_cache.dart
git commit -m "feat(flutter): add createFarmRemote and createInstallationRemote to ApiCache"
```

---

## Task 6: Dashboard 空状态引导

**Files:**
- Modify: `Mobile/mobile_app/lib/features/dashboard/presentation/dashboard_page.dart`
- Modify: `Mobile/mobile_app/lib/app/app_route.dart`
- Modify: `Mobile/mobile_app/lib/app/app_router.dart`

- [ ] **Step 1: 在 AppRoute 枚举中添加 farmCreation 路由**

`app/app_route.dart` 添加：
```dart
farmCreation('/farm/create', '创建牧场', Icons.add_business_outlined),
```

- [ ] **Step 2: 在 AppRouter 中添加 GoRoute 配置**

- [ ] **Step 3: 在 DashboardPage 中添加空牧场判断分支**

通过 `ref.watch(farmSwitcherControllerProvider)` 检测 `farms.isEmpty`，渲染 `_EmptyFarmGuide` 引导卡片（"您还没有牧场" + 创建按钮）。

- [ ] **Step 4: 验证编译**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/features/dashboard/ Mobile/mobile_app/lib/app/
git commit -m "feat(flutter): add empty farm guide on Dashboard when owner has no farms"
```

---

## Task 7: 牧场创建向导 — Step 1 + Step 3

**Files:**
- Create: `Mobile/mobile_app/lib/features/farm_creation/presentation/farm_creation_wizard_page.dart`
- Create: `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_basic_info.dart`
- Create: `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_complete.dart`

- [ ] **Step 1: 创建向导容器页面**

`farm_creation_wizard_page.dart` — 维护 `_step` 和 `_createdFarmId` 状态，根据 step 切换渲染三个子页面。

- [ ] **Step 2: 创建 Step 1 基本信息页面**

`wizard_step_basic_info.dart` — 表单（牧场名必填、面积可选）+ flutter_map 点击选中心点。提交时调用 `ApiCache.instance.createFarmRemote(...)`，成功后设 `activeFarmId` 并跳 Step 2。

- [ ] **Step 3: 创建 Step 3 完成页面**

`wizard_step_complete.dart` — 显示摘要 + [进入牧场] 按钮。点击时触发 ApiCache.init 刷新后跳转 Dashboard。

- [ ] **Step 4: 验证编译**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/features/farm_creation/
git commit -m "feat(flutter): add farm creation wizard — Step 1 basic info + Step 3 complete"
```

---

## Task 8: 草稿围栏编辑器（向导 Step 2）

**Files:**
- Create: `Mobile/mobile_app/lib/features/farm_creation/domain/draft_fence_state.dart`
- Create: `Mobile/mobile_app/lib/features/farm_creation/presentation/draft_polygon_editor.dart`
- Create: `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_fence_drawing.dart`

- [ ] **Step 1: 创建草稿围栏状态模型**

`draft_fence_state.dart` — 不可变状态，持有 `List<LatLng> points` + undoStack + redoStack。

- [ ] **Step 2: 创建草稿多边形编辑器**

`draft_polygon_editor.dart` — 复用 `FenceEditOperations` 的顶点操作方法，使用 `DraftFenceState` 而非 `FenceEditSession`。flutter_map 上显示 PolygonLayer + 可拖拽顶点。核心交互：点击添加顶点、拖拽移动、长按删除、撤销/重做。

- [ ] **Step 3: 创建 Step 2 围栏绘制页面**

`wizard_step_fence_drawing.dart` — 包含 DraftPolygonEditor + "保存围栏"按钮 + "稍后设置"跳过按钮。保存时调用 `ApiCache.instance.createFenceRemote(...)`。

- [ ] **Step 4: 验证编译 + 运行测试**

Run: `cd Mobile/mobile_app && flutter analyze && flutter test`
Expected: No issues / ALL PASS

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/features/farm_creation/
git commit -m "feat(flutter): add draft polygon editor for fence drawing in farm creation wizard"
```

---

## Task 9: FarmSwitcherController Mock 模式适配

**Files:**
- Modify: `Mobile/mobile_app/lib/features/farm_switcher/farm_switcher_controller.dart`

- [ ] **Step 1: 在 mock 状态中增加空牧场分支**

通过 `--dart-define=EMPTY_FARM_DEMO=true` 激活空牧场场景，`_mockState` 中判断此标志返回空农场列表。

- [ ] **Step 2: 验证编译**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add Mobile/mobile_app/lib/features/farm_switcher/farm_switcher_controller.dart
git commit -m "feat(flutter): add empty farm demo mode for FarmSwitcherController"
```

---

## Task 10: 设备-牲畜绑定 UI 入口

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/devices_page.dart`（或对应的设备管理页面）

- [ ] **Step 1: 在设备操作中添加"安装到牲畜"选项**

弹出对话框让用户选择牲畜，调用 `ApiCache.instance.createInstallationRemote(...)`。

- [ ] **Step 2: 验证编译**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add Mobile/mobile_app/lib/features/
git commit -m "feat(flutter): add device-to-livestock installation UI entry point"
```

---

## Task 11: 集成验证

**Files:** 无新文件

- [ ] **Step 1: 后端 API 手动验证**

1. platform_admin 创建新租户 + owner 用户
2. owner 登录 → GET /farms 返回空列表
3. owner 创建牧场 → POST /farms 成功 → 验证 user_farm_assignments 已写入
4. GET /farms/{id}/dashboard 返回统计字段

- [ ] **Step 2: Flutter 端到端验证**

1. 用新 owner 账号登录
2. 验证看到空状态引导卡片
3. 完成三步向导（牧场 → 围栏 → 完成）
4. 验证 Dashboard 正常显示
5. 添加设备、牲畜、安装设备

- [ ] **Step 3: 全量测试**

```bash
cd smart-livestock-server && ./gradlew test
cd Mobile/mobile_app && flutter test
```
Expected: ALL PASS

- [ ] **Step 4: 更新完成记录表**

---

## 依赖关系图

```
Task 1 (UserFarmAssignment Repository) → Task 2 (FarmApplicationService 自动关联)
Task 2 → Task 3 (FarmController 传 userId)
Task 3 → Task 11 (集成验证)

Task 4 (DashboardController) → Task 11

Task 5 (ApiCache) → Task 7 (向导页面)
Task 5 → Task 10 (设备-牲畜绑定 UI)

Task 6 (Dashboard 空状态) → Task 11

Task 7 (向导 Step 1+3) → Task 8 (草稿围栏 Step 2) → Task 11

Task 9 (Mock 适配) — 独立

可并行路径：
- Task 1-3 (后端) 与 Task 5-9 (前端) 可并行
- Task 4 (后端 dashboard) 独立
- Task 9 (mock 适配) 独立
```
