# 牲畜 / 设备 / 安装管理后端实施计划

> **执行方式说明：** 本计划按 Task 逐个执行。每个 Task 内的步骤用 `- [ ]` 复选框标记进度。

**目标：** 补全牲畜、设备、安装三个模块的后端 CRUD，实现全字段持久化、全局唯一性约束、安装校验规则。

**架构：** 应用层编排（方案 A）。跨聚合校验规则放在 ApplicationService 中。领域实体封装字段更新。Command 对象与现有代码库风格一致。不新增 domain service。

**技术栈：** Spring Boot 3.3 + Java 17 + Gradle + JUnit 5 + Mockito

**设计文档：** `docs/superpowers/specs/2026-07-01-livestock-device-management-design.md`

---

## 文件结构

**新增文件：**
- `ranch/application/command/CreateLivestockCommand.java` — 牲畜创建命令
- `ranch/application/command/UpdateLivestockCommand.java` — 牲畜更新命令
- `iot/application/command/UpdateDeviceCommand.java` — 设备更新命令
- `ranch/application/LivestockApplicationServiceTest.java`（测试目录）— 单元测试
- `iot/application/DeviceApplicationServiceTest.java`（测试目录）— 单元测试
- `iot/application/InstallationApplicationServiceTest.java`（测试目录）— 单元测试

**修改文件：**
- `ranch/domain/model/Livestock.java` — 新增 `updateInfo()`
- `ranch/application/LivestockApplicationService.java` — 完整 create/update/delete
- `ranch/interfaces/LivestockController.java` — 从 body 提取全字段
- `ranch/domain/port/IoTQueryPort.java` — 新增 `hasActiveInstallationByLivestock`
- `ranch/infrastructure/acl/IoTQueryPortImpl.java` — 实现新方法
- `iot/domain/model/Device.java` — 新增 `updateInfo()`
- `iot/application/command/RegisterDeviceCommand.java` — 增加 `devEui`
- `iot/application/DeviceApplicationService.java` — 唯一性校验 + update
- `iot/interfaces/DeviceController.java` — 提取 devEui + 实装 PUT
- `iot/domain/repository/InstallationRepository.java` — 新增 per-type 查询
- `iot/infrastructure/persistence/SpringDataInstallationRepository.java` — join 查询
- `iot/infrastructure/persistence/JpaInstallationRepositoryImpl.java` — 映射新方法
- `iot/application/InstallationApplicationService.java` — 校验链
- `iot/interfaces/InstallationController.java` — 补 @PreAuthorize

路径均相对于 `smart-livestock-server/src/main/java/com/smartlivestock/`（源码）和 `smart-livestock-server/src/test/java/com/smartlivestock/`（测试）。

---

### Task 1：牲畜领域模型 + Command 对象

**文件：**
- 新增：`ranch/application/command/CreateLivestockCommand.java`
- 新增：`ranch/application/command/UpdateLivestockCommand.java`
- 修改：`ranch/domain/model/Livestock.java`

- [ ] **步骤 1：创建 `CreateLivestockCommand.java`**

```java
package com.smartlivestock.ranch.application.command;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateLivestockCommand(
        Long farmId,
        String livestockCode,
        String breed,
        String gender,
        LocalDate birthDate,
        BigDecimal weight
) {}
```

- [ ] **步骤 2：创建 `UpdateLivestockCommand.java`**

```java
package com.smartlivestock.ranch.application.command;

import java.math.BigDecimal;
import java.time.LocalDate;

public record UpdateLivestockCommand(
        String livestockCode,
        String breed,
        String gender,
        LocalDate birthDate,
        BigDecimal weight
) {}
```

- [ ] **步骤 3：在 `Livestock.java` 中添加 `updateInfo()` 方法**

在现有的 `updatePosition` 方法之后添加：

```java
/**
 * Update editable livestock info fields.
 */
public void updateInfo(String livestockCode, String breed, String gender,
                       LocalDate birthDate, BigDecimal weight) {
    this.livestockCode = livestockCode;
    this.breed = breed;
    this.gender = gender;
    this.birthDate = birthDate;
    this.weight = weight;
}
```

- [ ] **步骤 4：编译验证**

运行：`cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
预期：无错误

- [ ] **步骤 5：提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/command/CreateLivestockCommand.java smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/command/UpdateLivestockCommand.java smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Livestock.java
git commit -m "feat(ranch): livestock command objects + updateInfo domain method"
```

---

### Task 2：牲畜 ApplicationService — Create + Update + 全局唯一性校验

**文件：**
- 修改：`ranch/application/LivestockApplicationService.java`
- 测试：`ranch/application/LivestockApplicationServiceTest.java`（测试目录）

- [ ] **步骤 1：编写失败测试**

创建 `src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java`：

```java
package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LivestockApplicationServiceTest {

    @Mock
    private LivestockRepository livestockRepository;

    @Mock
    private HealthQueryPort healthQueryPort;

    @InjectMocks
    private LivestockApplicationService service;

    private CreateLivestockCommand createCommand() {
        return new CreateLivestockCommand(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450.5"));
    }

    @Test
    void shouldCreateLivestockWithAllFields() {
        when(livestockRepository.findByLivestockCode("COW-001")).thenReturn(Optional.empty());
        when(livestockRepository.save(any(Livestock.class))).thenAnswer(inv -> {
            Livestock l = inv.getArgument(0);
            l.setId(10L);
            return l;
        });

        var result = service.createLivestock(createCommand());

        assertThat(result.livestockCode()).isEqualTo("COW-001");
        assertThat(result.breed()).isEqualTo("安格斯");
        assertThat(result.gender()).isEqualTo("MALE");
        assertThat(result.weight()).isEqualByComparingTo(new BigDecimal("450.5"));
    }

    @Test
    void shouldRejectDuplicateLivestockCode() {
        Livestock existing = new Livestock();
        existing.setId(99L);
        when(livestockRepository.findByLivestockCode("COW-001")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> service.createLivestock(createCommand()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }

    @Test
    void shouldUpdateLivestockFields() {
        Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450"));
        existing.setId(10L);
        when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(livestockRepository.save(any(Livestock.class))).thenAnswer(inv -> inv.getArgument(0));

        var cmd = new UpdateLivestockCommand("COW-001", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        var result = service.updateLivestock(10L, cmd);

        assertThat(result.breed()).isEqualTo("和牛");
        assertThat(result.gender()).isEqualTo("FEMALE");
        assertThat(result.weight()).isEqualByComparingTo(new BigDecimal("500"));
    }

    @Test
    void shouldRejectUpdateWithDuplicateCode() {
        Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450"));
        existing.setId(10L);
        Livestock other = new Livestock(2L, "COW-002", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        other.setId(20L);

        when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(livestockRepository.findByLivestockCode("COW-002")).thenReturn(Optional.of(other));

        var cmd = new UpdateLivestockCommand("COW-002", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        assertThatThrownBy(() -> service.updateLivestock(10L, cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.ranch.application.LivestockApplicationServiceTest" 2>&1 | tail -20`
预期：失败（`createLivestock` 方法签名不匹配）

- [ ] **步骤 3：实现 `createLivestock` 和 `updateLivestock`**

在 `LivestockApplicationService.java` 中，添加 import：
```java
import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
```

替换现有的 `createLivestock` 方法：

```java
@Transactional
public LivestockDto createLivestock(CreateLivestockCommand command) {
    if (livestockRepository.findByLivestockCode(command.livestockCode()).isPresent()) {
        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                "牲畜编号已存在: " + command.livestockCode());
    }
    Livestock livestock = new Livestock();
    livestock.setFarmId(command.farmId());
    livestock.setLivestockCode(command.livestockCode());
    livestock.setBreed(command.breed());
    livestock.setGender(command.gender());
    livestock.setBirthDate(command.birthDate());
    livestock.setWeight(command.weight());
    Livestock saved = livestockRepository.save(livestock);
    return LivestockDto.from(saved);
}
```

在 `updatePosition` 之后添加新方法：

```java
@Transactional
public LivestockDto updateLivestock(Long id, UpdateLivestockCommand command) {
    Livestock livestock = livestockRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
    if (!command.livestockCode().equals(livestock.getLivestockCode())) {
        livestockRepository.findByLivestockCode(command.livestockCode())
                .ifPresent(existing -> {
                    if (!existing.getId().equals(id)) {
                        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                "牲畜编号已存在: " + command.livestockCode());
                    }
                });
    }
    livestock.updateInfo(command.livestockCode(), command.breed(),
            command.gender(), command.birthDate(), command.weight());
    Livestock saved = livestockRepository.save(livestock);
    return LivestockDto.from(saved);
}
```

- [ ] **步骤 4：运行测试确认通过**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.ranch.application.LivestockApplicationServiceTest" 2>&1 | tail -10`
预期：4 个测试全部通过

- [ ] **步骤 5：提交**

```bash
git add smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/LivestockApplicationService.java
git commit -m "feat(ranch): livestock create/update with global uniqueness validation"
```

---

### Task 3：牲畜删除守卫 + IoTQueryPort 扩展

**文件：**
- 修改：`ranch/domain/port/IoTQueryPort.java`
- 修改：`ranch/infrastructure/acl/IoTQueryPortImpl.java`
- 修改：`ranch/application/LivestockApplicationService.java`
- 测试：`ranch/application/LivestockApplicationServiceTest.java`（新增测试）

- [ ] **步骤 1：在 `IoTQueryPort.java` 接口中新增方法**

```java
boolean hasActiveInstallationByLivestock(Long livestockId);
```

- [ ] **步骤 2：在 `IoTQueryPortImpl.java` 中实现**

添加方法（`installationRepository` 已注入，无需新依赖）：

```java
@Override
public boolean hasActiveInstallationByLivestock(Long livestockId) {
    return installationRepository.findByLivestockId(livestockId).stream()
            .anyMatch(i -> i.getRemovedAt() == null);
}
```

- [ ] **步骤 3：编写删除守卫的失败测试**

在 `LivestockApplicationServiceTest.java` 中新增：
- 在类的字段区域添加 `@Mock private com.smartlivestock.ranch.domain.port.IoTQueryPort iotQueryPort;`

```java
@Test
void shouldRejectDeleteWithActiveInstallation() {
    Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
            LocalDate.of(2024, 3, 15), new BigDecimal("450"));
    existing.setId(10L);
    when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
    when(iotQueryPort.hasActiveInstallationByLivestock(10L)).thenReturn(true);

    assertThatThrownBy(() -> service.deleteLivestock(10L))
            .isInstanceOf(ApiException.class)
            .satisfies(ex -> {
                ApiException apiEx = (ApiException) ex;
                assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
            });
}
```

- [ ] **步骤 4：运行测试确认失败**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.ranch.application.LivestockApplicationServiceTest" 2>&1 | tail -10`
预期：失败（`deleteLivestock` 尚未检查 IoTQueryPort）

- [ ] **步骤 5：更新 `LivestockApplicationService.java` 的 `deleteLivestock` 方法**

注入 `IoTQueryPort`：该类使用 `@RequiredArgsConstructor`（Lombok），只需添加 `private final` 字段：

```java
private final IoTQueryPort iotQueryPort;
```

替换 `deleteLivestock`：

```java
@Transactional
public void deleteLivestock(Long id) {
    Livestock livestock = livestockRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
    if (iotQueryPort.hasActiveInstallationByLivestock(id)) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
                "该牲畜仍有活跃设备安装，请先卸载");
    }
    livestockRepository.deleteById(id);
}
```

添加 `import com.smartlivestock.ranch.domain.port.IoTQueryPort;`（确认是否已存在 — 该类已使用 `HealthQueryPort`，可能已有 import）。

- [ ] **步骤 6：运行测试确认通过**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.ranch.application.LivestockApplicationServiceTest" 2>&1 | tail -10`
预期：5 个测试全部通过

- [ ] **步骤 7：提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/port/IoTQueryPort.java smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/acl/IoTQueryPortImpl.java smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/LivestockApplicationService.java smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java
git commit -m "feat(ranch): livestock delete guard — block delete with active installations"
```

---

### Task 4：设备领域模型 + Command 对象

**文件：**
- 修改：`iot/application/command/RegisterDeviceCommand.java`
- 新增：`iot/application/command/UpdateDeviceCommand.java`
- 修改：`iot/domain/model/Device.java`

- [ ] **步骤 1：扩展 `RegisterDeviceCommand.java`，增加 `devEui`**

替换整个文件：

```java
package com.smartlivestock.iot.application.command;

import com.smartlivestock.iot.domain.model.DeviceType;

public record RegisterDeviceCommand(String deviceCode, DeviceType deviceType, Long tenantId, String devEui) {
}
```

- [ ] **步骤 2：创建 `UpdateDeviceCommand.java`**

```java
package com.smartlivestock.iot.application.command;

public record UpdateDeviceCommand(String deviceCode, String devEui) {
}
```

- [ ] **步骤 3：在 `Device.java` 中添加 `updateInfo()` 方法**

在现有的 `updateRuntimeStatus` 方法之后添加：

```java
/**
 * Update editable device info fields.
 */
public void updateInfo(String deviceCode, String devEui) {
    this.deviceCode = deviceCode;
    this.devEui = devEui;
}
```

- [ ] **步骤 4：修复编译 — 更新 RegisterDeviceCommand 的调用方**

搜索旧的三参数构造函数调用点：`rg "new RegisterDeviceCommand" smart-livestock-server/src/`

主要调用点在 `DeviceController.java` 中，需在末尾传入 `body.get("devEui")`。

- [ ] **步骤 5：编译验证**

运行：`cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
预期：无错误

- [ ] **步骤 6：提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/iot/application/command/RegisterDeviceCommand.java smart-livestock-server/src/main/java/com/smartlivestock/iot/application/command/UpdateDeviceCommand.java smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/model/Device.java
git commit -m "feat(iot): device command objects extended + updateInfo domain method"
```

---

### Task 5：设备 ApplicationService — Register + Update + 全局唯一性校验

**文件：**
- 修改：`iot/application/DeviceApplicationService.java`
- 测试：`iot/application/DeviceApplicationServiceTest.java`（测试目录）

- [ ] **步骤 1：编写失败测试**

创建 `src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java`：

```java
package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceApplicationServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private DeviceApplicationService service;

    @Test
    void shouldRegisterDeviceWithDevEui() {
        when(deviceRepository.findByDeviceCode("DEV-001")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        var cmd = new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, "AABBCCDDEEFF0011");
        var result = service.registerDevice(cmd);

        assertThat(result.deviceCode()).isEqualTo("DEV-001");
        assertThat(result.devEui()).isEqualTo("AABBCCDDEEFF0011");
    }

    @Test
    void shouldRejectDuplicateDeviceCode() {
        Device existing = new Device();
        existing.setId(99L);
        when(deviceRepository.findByDeviceCode("DEV-001")).thenReturn(Optional.of(existing));

        var cmd = new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, null);
        assertThatThrownBy(() -> service.registerDevice(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }

    @Test
    void shouldUpdateDeviceCodeAndDevEui() {
        Device existing = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        existing.setStatus(DeviceStatus.ACTIVE);
        existing.setId(10L);
        when(deviceRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(deviceRepository.findByDeviceCode("DEV-002")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        var cmd = new UpdateDeviceCommand("DEV-002", "AABBCCDDEEFF0022");
        var result = service.updateDevice(10L, cmd);

        assertThat(result.deviceCode()).isEqualTo("DEV-002");
        assertThat(result.devEui()).isEqualTo("AABBCCDDEEFF0022");
    }

    @Test
    void shouldRejectUpdateWithDuplicateCode() {
        Device existing = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        existing.setId(10L);
        Device other = new Device(2L, "DEV-002", DeviceType.CAPSULE, null);
        other.setId(20L);

        when(deviceRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(deviceRepository.findByDeviceCode("DEV-002")).thenReturn(Optional.of(other));

        var cmd = new UpdateDeviceCommand("DEV-002", null);
        assertThatThrownBy(() -> service.updateDevice(10L, cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.iot.application.DeviceApplicationServiceTest" 2>&1 | tail -20`
预期：失败（`registerDevice` 签名旧，`updateDevice` 不存在）

- [ ] **步骤 3：更新 `DeviceApplicationService.java` 的 `registerDevice` 方法**

替换现有的 `registerDevice`：

```java
@Transactional
public DeviceDto registerDevice(RegisterDeviceCommand command) {
    if (deviceRepository.findByDeviceCode(command.deviceCode()).isPresent()) {
        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                "设备编号已存在: " + command.deviceCode());
    }
    Device device = new Device();
    device.setTenantId(command.tenantId());
    device.setDeviceCode(command.deviceCode());
    device.setDeviceType(command.deviceType());
    device.setDevEui(command.devEui());
    Device saved = deviceRepository.save(device);
    return DeviceDto.from(saved);
}
```

- [ ] **步骤 4：在 `DeviceApplicationService.java` 中添加 `updateDevice` 方法**

添加 import：`import com.smartlivestock.iot.application.command.UpdateDeviceCommand;`

在 `registerDevice` 之后添加：

```java
@Transactional
public DeviceDto updateDevice(Long id, UpdateDeviceCommand command) {
    Device device = deviceRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + id));
    if (!command.deviceCode().equals(device.getDeviceCode())) {
        deviceRepository.findByDeviceCode(command.deviceCode())
                .ifPresent(existing -> {
                    if (!existing.getId().equals(id)) {
                        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                "设备编号已存在: " + command.deviceCode());
                    }
                });
    }
    device.updateInfo(command.deviceCode(), command.devEui());
    Device saved = deviceRepository.save(device);
    return DeviceDto.from(saved);
}
```

- [ ] **步骤 5：运行测试确认通过**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.iot.application.DeviceApplicationServiceTest" 2>&1 | tail -10`
预期：4 个测试全部通过

- [ ] **步骤 6：提交**

```bash
git add smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java smart-livestock-server/src/main/java/com/smartlivestock/iot/application/DeviceApplicationService.java
git commit -m "feat(iot): device register/update with global uniqueness validation"
```

---

### Task 6：安装 Repository — Per-Type 查询

**文件：**
- 修改：`iot/domain/repository/InstallationRepository.java`
- 修改：`iot/infrastructure/persistence/SpringDataInstallationRepository.java`
- 修改：`iot/infrastructure/persistence/JpaInstallationRepositoryImpl.java`

- [ ] **步骤 1：在 `InstallationRepository.java` 接口中新增方法**

添加 import：`import com.smartlivestock.iot.domain.model.DeviceType;`

```java
Optional<Installation> findActiveByLivestockIdAndDeviceType(Long livestockId, DeviceType deviceType);
```

- [ ] **步骤 2：在 `SpringDataInstallationRepository.java` 中添加 join 查询**

添加 import：`import org.springframework.data.jpa.repository.Query;` 和 `import org.springframework.data.repository.query.Param;`

```java
@Query("SELECT i FROM InstallationJpaEntity i JOIN DeviceJpaEntity d ON i.deviceId = d.id " +
       "WHERE i.livestockId = :livestockId AND i.removedAt IS NULL AND d.deviceType = :deviceType")
Optional<InstallationJpaEntity> findActiveByLivestockIdAndDeviceType(
        @Param("livestockId") Long livestockId, @Param("deviceType") String deviceType);
```

- [ ] **步骤 3：在 `JpaInstallationRepositoryImpl.java` 中实现**

添加 import：`import com.smartlivestock.iot.domain.model.DeviceType;`

```java
@Override
public Optional<Installation> findActiveByLivestockIdAndDeviceType(Long livestockId, DeviceType deviceType) {
    return springDataRepo.findActiveByLivestockIdAndDeviceType(livestockId, deviceType.name())
            .map(InstallationMapper::toDomain);
}
```

- [ ] **步骤 4：编译验证**

运行：`cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
预期：无错误

- [ ] **步骤 5：提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/repository/InstallationRepository.java smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/SpringDataInstallationRepository.java smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/JpaInstallationRepositoryImpl.java
git commit -m "feat(iot): installation repository — per-type active installation query"
```

---

### Task 7：安装 ApplicationService — 校验链

**文件：**
- 修改：`iot/application/InstallationApplicationService.java`
- 测试：`iot/application/InstallationApplicationServiceTest.java`（测试目录）

- [ ] **步骤 1：编写失败测试**

创建 `src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java`：

```java
package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InstallationApplicationServiceTest {

    @Mock
    private InstallationRepository installationRepository;

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private InstallationApplicationService service;

    @Test
    void shouldRejectInstallOnNonActiveDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.INVENTORY);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DEVICE_NOT_ACTIVE);
                });
    }

    @Test
    void shouldRejectInstallAlreadyInstalledDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        Installation existing = new Installation(1L, 10L, 100L);
        existing.setId(50L);
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.of(existing));

        var cmd = new InstallDeviceCommand(1L, 20L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    void shouldRejectInstallDuplicateDeviceType() {
        Device device = new Device(1L, "DEV-002", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.empty());
        Installation existing = new Installation(2L, 10L, 100L);
        existing.setId(50L);
        when(installationRepository.findActiveByLivestockIdAndDeviceType(10L, DeviceType.TRACKER))
                .thenReturn(Optional.of(existing));

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    void shouldAllowInstallDifferentDeviceTypes() {
        Device gps = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        gps.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(gps));
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.empty());
        when(installationRepository.findActiveByLivestockIdAndDeviceType(10L, DeviceType.TRACKER))
                .thenReturn(Optional.empty());
        when(installationRepository.save(any(Installation.class))).thenAnswer(inv -> {
            Installation i = inv.getArgument(0);
            i.setId(1L);
            return i;
        });

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        var result = service.install(cmd);

        assertThat(result.deviceId()).isEqualTo(1L);
        assertThat(result.livestockId()).isEqualTo(10L);
        assertThat(result.active()).isTrue();
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.iot.application.InstallationApplicationServiceTest" 2>&1 | tail -20`
预期：失败（install 无校验，DeviceRepository 未注入）

- [ ] **步骤 3：更新 `InstallationApplicationService.java` — 注入 DeviceRepository + 校验链**

添加 import：
```java
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
```

添加字段 `private final DeviceRepository deviceRepository;`（类使用 `@RequiredArgsConstructor`，Lombok 自动注入）。

替换现有的 `install` 方法：

```java
@Transactional
public InstallationDto install(InstallDeviceCommand command) {
    Device device = deviceRepository.findById(command.deviceId())
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + command.deviceId()));
    if (device.getStatus() != DeviceStatus.ACTIVE) {
        throw new ApiException(ErrorCode.DEVICE_NOT_ACTIVE,
                "设备未激活，无法安装: " + command.deviceId());
    }
    if (installationRepository.findActiveByDeviceId(command.deviceId()).isPresent()) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
                "设备已安装在其他牲畜上: " + command.deviceId());
    }
    if (installationRepository.findActiveByLivestockIdAndDeviceType(
            command.livestockId(), device.getDeviceType()).isPresent()) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
                "该牲畜已安装同类型设备: " + device.getDeviceType());
    }
    Installation installation = new Installation(command.deviceId(), command.livestockId(), command.operatorId());
    Installation saved = installationRepository.save(installation);
    return InstallationDto.from(saved);
}
```

- [ ] **步骤 4：运行测试确认通过**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.iot.application.InstallationApplicationServiceTest" 2>&1 | tail -10`
预期：4 个测试全部通过

- [ ] **步骤 5：提交**

```bash
git add smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java smart-livestock-server/src/main/java/com/smartlivestock/iot/application/InstallationApplicationService.java
git commit -m "feat(iot): installation validation chain — device status + per-type uniqueness"
```

---

### Task 8：Controller 更新

**文件：**
- 修改：`ranch/interfaces/LivestockController.java`
- 修改：`iot/interfaces/DeviceController.java`
- 修改：`iot/interfaces/InstallationController.java`

- [ ] **步骤 1：更新 `LivestockController.java` — POST 和 PUT**

添加 import：
```java
import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
import java.math.BigDecimal;
import java.time.LocalDate;
```

替换 `createLivestock` 方法：

```java
@PostMapping
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
@QuotaCheck(feature = "livestock_management")
public ResponseEntity<ApiResponse<LivestockDto>> createLivestock(
        @PathVariable Long farmId,
        @RequestBody Map<String, Object> body) {
    CreateLivestockCommand command = new CreateLivestockCommand(
            farmId,
            (String) body.get("livestockCode"),
            (String) body.get("breed"),
            (String) body.get("gender"),
            body.get("birthDate") != null ? LocalDate.parse((String) body.get("birthDate")) : null,
            body.get("weight") != null ? new BigDecimal(body.get("weight").toString()) : null
    );
    LivestockDto livestock = livestockApplicationService.createLivestock(command);
    return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(livestock));
}
```

替换 `updateLivestock` 方法：

```java
@PutMapping("/{livestockId}")
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
public ResponseEntity<ApiResponse<LivestockDto>> updateLivestock(
        @PathVariable Long farmId,
        @PathVariable Long livestockId,
        @RequestBody Map<String, Object> body) {
    UpdateLivestockCommand command = new UpdateLivestockCommand(
            (String) body.get("livestockCode"),
            (String) body.get("breed"),
            (String) body.get("gender"),
            body.get("birthDate") != null ? LocalDate.parse((String) body.get("birthDate")) : null,
            body.get("weight") != null ? new BigDecimal(body.get("weight").toString()) : null
    );
    LivestockDto livestock = livestockApplicationService.updateLivestock(livestockId, command);
    return ResponseEntity.ok(ApiResponse.ok(livestock));
}
```

- [ ] **步骤 2：更新 `DeviceController.java` — POST 和 PUT**

替换 `registerDevice` 方法以提取 `devEui`：

```java
@PostMapping
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
public ResponseEntity<ApiResponse<DeviceDto>> registerDevice(
        @PathVariable Long farmId,
        @RequestBody Map<String, Object> body) {
    Long tenantId = TenantContext.getCurrentTenant();
    String deviceTypeStr = (String) body.get("deviceType");
    DeviceType deviceType = resolveDeviceType(deviceTypeStr);
    RegisterDeviceCommand command = new RegisterDeviceCommand(
            (String) body.get("deviceCode"),
            deviceType,
            tenantId,
            (String) body.get("devEui")
    );
    DeviceDto device = deviceApplicationService.registerDevice(command);
    return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(device));
}
```

替换 `updateDevice` 方法：

```java
@PutMapping("/{deviceId}")
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
public ResponseEntity<ApiResponse<DeviceDto>> updateDevice(
        @PathVariable Long farmId,
        @PathVariable Long deviceId,
        @RequestBody Map<String, Object> body) {
    UpdateDeviceCommand command = new UpdateDeviceCommand(
            (String) body.get("deviceCode"),
            (String) body.get("devEui")
    );
    DeviceDto device = deviceApplicationService.updateDevice(deviceId, command);
    return ResponseEntity.ok(ApiResponse.ok(device));
}
```

添加 import：`import com.smartlivestock.iot.application.command.UpdateDeviceCommand;`

- [ ] **步骤 3：更新 `InstallationController.java` — 补 @PreAuthorize**

给 `installDevice`（POST）和 `uninstallDevice`（PUT uninstall）方法添加权限注解。

添加 import：`import org.springframework.security.access.prepost.PreAuthorize;`

`installDevice` 方法注解改为：
```java
@PostMapping
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
```

`uninstallDevice` 方法注解改为：
```java
@PutMapping("/{installationId}/uninstall")
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
```

- [ ] **步骤 4：编译验证**

运行：`cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
预期：无错误

- [ ] **步骤 5：提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/LivestockController.java smart-livestock-server/src/main/java/com/smartlivestock/iot/interfaces/DeviceController.java smart-livestock-server/src/main/java/com/smartlivestock/iot/interfaces/InstallationController.java
git commit -m "feat: controller updates — full-field livestock/device create+update, installation auth"
```

---

### Task 9：全量编译 + 测试验证

**文件：** 无（仅验证）

- [ ] **步骤 1：全量编译**

运行：`cd smart-livestock-server && ./gradlew compileJava compileTestJava -q 2>&1 | tail -20`
预期：BUILD SUCCESSFUL，无错误

- [ ] **步骤 2：运行全部新增测试**

运行：`cd smart-livestock-server && ./gradlew test --tests "*.ranch.application.LivestockApplicationServiceTest" --tests "*.iot.application.DeviceApplicationServiceTest" --tests "*.iot.application.InstallationApplicationServiceTest" 2>&1 | tail -20`
预期：全部通过

- [ ] **步骤 3：运行现有测试检查回归**

运行：`cd smart-livestock-server && ./gradlew test 2>&1 | tail -20`
预期：BUILD SUCCESSFUL，无回归（如有预存失败，确认非本次变更导致）

- [ ] **步骤 4：如有修复，提交**

```bash
git add -A
git commit -m "fix: post-verification fixes"
```
