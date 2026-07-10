# Livestock / Device / Installation Management Design

**Date**: 2026-07-01
**Status**: Approved
**Scope**: Backend (Spring Boot `smart-livestock-server/`)

## Problem

The three core management modules — livestock, device, and installation — have skeletal CRUD endpoints but key functionality is stubbed:

- **Livestock create** only persists `livestockCode`; breed, gender, birthDate, weight are silently discarded.
- **Livestock update** is a no-op (returns existing data unchanged).
- **Device register** only persists `deviceCode` + `deviceType`; `devEui` is discarded.
- **Device update** is a no-op.
- **Installation install** has no validation: no device status check, no duplicate check, no per-type constraint.
- **Livestock delete** does not check for active installations.
- No uniqueness constraints on `livestockCode` or `deviceCode`.

## Business Rules (Confirmed)

| Rule | Decision |
|------|----------|
| `livestockCode` uniqueness | Globally unique (system-wide, not per-farm) |
| `deviceCode` uniqueness | Globally unique |
| Livestock create/update fields | breed, gender, birthDate, weight — all accepted |
| Device register fields | deviceCode (required), deviceType (required), devEui (optional) |
| Device update fields | deviceCode, devEui (deviceType is immutable) |
| Installation prerequisite | Device must be ACTIVE before installing |
| Per-livestock installation rule | One active installation per device type (e.g. GPS + capsule OK; two GPS not allowed) |
| Uninstall effect on device | No status change (device stays ACTIVE, can be reinstalled) |
| Delete livestock with active installation | Forbidden (409 STATE_CONFLICT) |

## Architecture: Application-Layer Orchestration (Option A)

Cross-aggregate validation rules live in ApplicationService. Domain entities keep their existing self-contained state-transition logic. This matches the existing codebase pattern (command objects + ApplicationService orchestration).

No new domain services. No new bounded contexts.

## Changes by Module

### 1. Livestock (Ranch Context)

#### Domain Model: `Livestock.java`

Add `updateInfo` method to encapsulate field updates within the aggregate:

```java
public void updateInfo(String livestockCode, String breed, String gender,
                       LocalDate birthDate, BigDecimal weight) {
    this.livestockCode = livestockCode;
    this.breed = breed;
    this.gender = gender;
    this.birthDate = birthDate;
    this.weight = weight;
}
```

#### Command Objects (new)

`ranch/application/command/CreateLivestockCommand.java`:
```java
public record CreateLivestockCommand(
    Long farmId, String livestockCode, String breed,
    String gender, LocalDate birthDate, BigDecimal weight
) {}
```

`ranch/application/command/UpdateLivestockCommand.java`:
```java
public record UpdateLivestockCommand(
    String livestockCode, String breed, String gender,
    LocalDate birthDate, BigDecimal weight
) {}
```

#### ApplicationService: `LivestockApplicationService.java`

- `createLivestock(CreateLivestockCommand)`:
  1. Call `livestockRepository.findByLivestockCode(code)` — if present, throw `DUPLICATE_RESOURCE`
  2. Construct `Livestock` with all fields
  3. Save and return DTO

- `updateLivestock(Long id, UpdateLivestockCommand)`:
  1. Load existing livestock (404 if not found)
  2. If `livestockCode` changed, check `findByLivestockCode` — if present AND id differs, throw `DUPLICATE_RESOURCE`
  3. Call `livestock.updateInfo(...)` then save

- `deleteLivestock(Long id)`:
  1. Load existing livestock (404 if not found)
  2. Call `iotQueryPort.hasActiveInstallationByLivestock(id)` — if true, throw `STATE_CONFLICT`
  3. Delete

#### IoTQueryPort Extension

Add to `ranch/domain/port/IoTQueryPort.java`:
```java
boolean hasActiveInstallationByLivestock(Long livestockId);
```

Implementation in `IoTQueryPortImpl` delegates to `installationRepository.findByLivestockId(livestockId)` and checks for any with `removedAt == null`.

#### Controller: `LivestockController.java`

Replace `Map<String, Object>` request bodies with typed extraction:
- POST body: extract `livestockCode`, `breed`, `gender`, `birthDate`, `weight` → construct `CreateLivestockCommand`
- PUT body: same fields → construct `UpdateLivestockCommand`

Keep `@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")` on POST/PUT/DELETE.

#### No Changes Needed

- `LivestockDto` — already includes all fields.
- `LivestockRepository` — already has `findByLivestockCode`.
- `LivestockJpaEntity` — already maps all fields.

### 2. Device (IoT Context)

#### Domain Model: `Device.java`

Add `updateInfo` method:
```java
public void updateInfo(String deviceCode, String devEui) {
    this.deviceCode = deviceCode;
    this.devEui = devEui;
}
```

#### Command Objects (modified / new)

Extend `RegisterDeviceCommand` to add `devEui`:
```java
public record RegisterDeviceCommand(
    String deviceCode, DeviceType deviceType, Long tenantId, String devEui
) {}
```

`iot/application/command/UpdateDeviceCommand.java` (new):
```java
public record UpdateDeviceCommand(String deviceCode, String devEui) {}
```

#### ApplicationService: `DeviceApplicationService.java`

- `registerDevice(RegisterDeviceCommand)`:
  1. Call `deviceRepository.findByDeviceCode(code)` — if present, throw `DUPLICATE_RESOURCE`
  2. Construct `Device` with all fields (including devEui)
  3. Save and return DTO

- `updateDevice(Long id, UpdateDeviceCommand)`:
  1. Load existing device (404 if not found)
  2. If `deviceCode` changed, check uniqueness (exclude self) — throw `DUPLICATE_RESOURCE` on conflict
  3. Call `device.updateInfo(...)` then save

#### Controller: `DeviceController.java`

- POST: extract `deviceCode`, `deviceType`, `devEui` from body → construct extended `RegisterDeviceCommand`
- PUT: replace no-op with real `updateDevice` call

#### No Changes Needed

- `DeviceDto` — already includes `devEui`.
- `DeviceRepository` — already has `findByDeviceCode`.
- `DeviceJpaEntity` — already maps `devEui`.

### 3. Installation (IoT Context)

#### Domain Model: `Installation.java`

No changes. Existing `remove()` logic is correct.

#### Repository Extension

Add to `InstallationRepository.java`:
```java
Optional<Installation> findActiveByLivestockIdAndDeviceType(Long livestockId, DeviceType deviceType);
```

This requires a join query (Installation -> Device to get deviceType). Implementation in `SpringDataInstallationRepository`:
```java
@Query("SELECT i FROM InstallationJpaEntity i JOIN DeviceJpaEntity d ON i.deviceId = d.id " +
       "WHERE i.livestockId = :livestockId AND i.removedAt IS NULL AND d.deviceType = :deviceType")
Optional<InstallationJpaEntity> findActiveByLivestockIdAndDeviceType(
    @Param("livestockId") Long livestockId, @Param("deviceType") String deviceType);
```

Map to domain in `JpaInstallationRepositoryImpl` (convert DeviceType enum to String for query).

#### ApplicationService: `InstallationApplicationService.java`

- `install(InstallDeviceCommand)`:
  1. Load device via `deviceRepository.findById` — 404 if not found
  2. Check `device.getStatus() == ACTIVE` — throw `DEVICE_NOT_ACTIVE` if not
  3. Check `installationRepository.findActiveByDeviceId(deviceId)` — throw `STATE_CONFLICT` if present (device already installed elsewhere)
  4. Check `installationRepository.findActiveByLivestockIdAndDeviceType(livestockId, device.getDeviceType())` — throw `STATE_CONFLICT` if present (livestock already has this device type)
  5. Create and save installation

Inject `DeviceRepository` into `InstallationApplicationService` (new dependency).

#### Controller: `InstallationController.java`

Add `@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")` to POST install and PUT uninstall endpoints.

## Error Handling

| Scenario | HTTP Status | ErrorCode | Message |
|----------|-------------|-----------|---------|
| livestockCode already exists | 409 | DUPLICATE_RESOURCE | "牲畜编号已存在: {code}" |
| deviceCode already exists | 409 | DUPLICATE_RESOURCE | "设备编号已存在: {code}" |
| Device not ACTIVE on install | 409 | DEVICE_NOT_ACTIVE | "设备未激活，无法安装: {deviceId}" |
| Device already installed elsewhere | 409 | STATE_CONFLICT | "设备已安装在其他牲畜上: {deviceId}" |
| Livestock already has this device type | 409 | STATE_CONFLICT | "该牲畜已安装同类型设备: {deviceType}" |
| Delete livestock with active installation | 409 | STATE_CONFLICT | "该牲畜仍有活跃设备安装，请先卸载" |

## Testing

Unit tests for ApplicationService validation rules:
- `LivestockApplicationServiceTest`: create with duplicate code -> DUPLICATE_RESOURCE; update with duplicate code -> DUPLICATE_RESOURCE; delete with active installation -> STATE_CONFLICT
- `DeviceApplicationServiceTest`: register with duplicate code -> DUPLICATE_RESOURCE; update with duplicate code -> DUPLICATE_RESOURCE
- `InstallationApplicationServiceTest`: install non-active device -> DEVICE_NOT_ACTIVE; install already-installed device -> STATE_CONFLICT; install duplicate type -> STATE_CONFLICT; successful install of different types on same livestock -> OK

Follow existing test patterns (JUnit 5 + Mockito mocks for repositories).

## Out of Scope

- Frontend (Flutter) form changes — deferred to a separate phase after backend APIs are verified.
- Seed data migrations — existing seed data remains valid (no schema changes).
- `findActiveByLivestockId` legacy method — left as-is; the new `findActiveByLivestockIdAndDeviceType` is the precise check.
- Device heartbeat / runtime status updates — unchanged.

## Files Changed (Summary)

**New files (3):**
- `ranch/application/command/CreateLivestockCommand.java`
- `ranch/application/command/UpdateLivestockCommand.java`
- `iot/application/command/UpdateDeviceCommand.java`

**Modified files (~12):**
- `ranch/domain/model/Livestock.java` — add `updateInfo()`
- `ranch/application/LivestockApplicationService.java` — full create/update/delete logic
- `ranch/interfaces/LivestockController.java` — typed body extraction
- `ranch/domain/port/IoTQueryPort.java` — add `hasActiveInstallationByLivestock`
- `ranch/infrastructure/acl/IoTQueryPortImpl.java` — implement new port method
- `iot/domain/model/Device.java` — add `updateInfo()`
- `iot/application/command/RegisterDeviceCommand.java` — add `devEui`
- `iot/application/DeviceApplicationService.java` — uniqueness check + update method
- `iot/interfaces/DeviceController.java` — extract devEui + real PUT
- `iot/domain/repository/InstallationRepository.java` — add per-type query
- `iot/infrastructure/persistence/SpringDataInstallationRepository.java` — join query
- `iot/infrastructure/persistence/JpaInstallationRepositoryImpl.java` — map new method
- `iot/application/InstallationApplicationService.java` — validation chain
- `iot/interfaces/InstallationController.java` — add @PreAuthorize

**New test files (3):**
- `ranch/application/LivestockApplicationServiceTest.java` (or extend existing)
- `iot/application/DeviceApplicationServiceTest.java` (or extend existing)
- `iot/application/InstallationApplicationServiceTest.java` (or extend existing)
