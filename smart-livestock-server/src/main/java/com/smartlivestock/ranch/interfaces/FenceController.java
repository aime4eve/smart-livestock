package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.FenceTrackDraftService;
import com.smartlivestock.ranch.application.FenceTrackParseService;
import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.application.dto.FenceTrackParseResultDto;
import com.smartlivestock.ranch.application.dto.TrackDraftCandidatesDto;
import com.smartlivestock.ranch.application.dto.TrackDraftSourceDto;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.platform.web.QuotaCheck;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/fences")
@RequiredArgsConstructor
public class FenceController {

    private static final Logger log = LoggerFactory.getLogger(FenceController.class);

    private final FenceApplicationService fenceApplicationService;
    private final FenceTrackParseService fenceTrackParseService;
    private final FenceTrackDraftService fenceTrackDraftService;
    private final IdentityQueryPort identityQueryPort;

    private void verifyFarmOwnership(Long farmId) {
        var farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFences(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        verifyFarmOwnership(farmId);
        List<FenceDto> fences = fenceApplicationService.listByFarm(farmId);
        Map<String, Object> data = Map.of(
                "items", fences,
                "page", page,
                "pageSize", pageSize,
                "total", fences.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    @QuotaCheck(feature = "fence_management")
    public ResponseEntity<ApiResponse<FenceDto>> createFence(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        CreateFenceCommand command = new CreateFenceCommand(
                farmId,
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color"),
                (String) body.get("fenceType"),
                (String) body.get("shape"),
                parseGenerationMetadata(body.get("generationMetadata"))
        );
        FenceDto fence = fenceApplicationService.createFence(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(fence));
    }

    /**
     * Stateless GPX track parse-preview for the fence "import GPX" flow
     * (NIX-213). Returns statistics + the cleaned point list; nothing is
     * persisted — the fence itself is still created via POST /fences.
     */
    @PostMapping(value = "/track-parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<FenceTrackParseResultDto>> parseTrack(
            @PathVariable Long farmId,
            @RequestParam("file") MultipartFile file) {
        verifyFarmOwnership(farmId);
        return ResponseEntity.ok(ApiResponse.ok(fenceTrackParseService.parse(file)));
    }

    /**
     * Fence track-draft source (spec §4.1): merged stride-sampled GPS points
     * of the selected trackers. Stateless preview — the fence itself is still
     * created via POST /fences. Validation failures surface as 400
     * VALIDATION_ERROR with error.trackDraft* message keys.
     */
    @PostMapping("/track-draft/source")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<TrackDraftSourceDto>> trackDraftSource(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        List<Long> deviceIds = parseDeviceIds(body.get("deviceIds"));
        Instant from = parseTrackDraftInstant(body.get("startTime"));
        Instant to = parseTrackDraftInstant(body.get("endTime"));
        return ResponseEntity.ok(ApiResponse.ok(
                fenceTrackDraftService.source(farmId, deviceIds, from, to)));
    }

    /**
     * Fence track-draft candidates (spec §4.2): this farm's trackers with an
     * active installation, plus the fence quota pre-check data.
     */
    @GetMapping("/track-draft/candidates")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<TrackDraftCandidatesDto>> trackDraftCandidates(
            @PathVariable Long farmId,
            @RequestParam(name = "days", defaultValue = "30") int days) {
        verifyFarmOwnership(farmId);
        if (days < 1 || days > 30) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftRangeTooLong");
        }
        return ResponseEntity.ok(ApiResponse.ok(fenceTrackDraftService.candidates(farmId, days)));
    }

    @GetMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<FenceDto>> getFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId) {
        verifyFarmOwnership(farmId);
        FenceDto fence = fenceApplicationService.getFence(fenceId);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    @SuppressWarnings("unchecked")
    @PutMapping("/{fenceId}")
    public ResponseEntity<? extends ApiResponse<?>> updateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        Integer expectedVersion = body.get("expectedVersion") != null
                ? ((Number) body.get("expectedVersion")).intValue() : null;
        UpdateFenceCommand command = new UpdateFenceCommand(
                (String) body.get("name"),
                parseVertices(body.get("vertices")),
                (String) body.get("color"),
                (String) body.get("shape"),
                expectedVersion
        );
        try {
            FenceDto fence = fenceApplicationService.updateFence(fenceId, command);
            return ResponseEntity.ok(ApiResponse.ok(fence));
        } catch (ApiException e) {
            if (e.getCode() == ErrorCode.STATE_CONFLICT) {
                FenceDto current = fenceApplicationService.getFence(fenceId);
                Map<String, Object> conflictData = Map.of(
                        "serverVersion", current.version(),
                        "serverVertices", current.vertices()
                );
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(ApiResponse.errorWithData(ErrorCode.STATE_CONFLICT, e.getMessage(), conflictData));
            }
            throw e;
        }
    }

    @PutMapping("/{fenceId}/force")
    @PreAuthorize("hasRole('PLATFORM_ADMIN')")
    public ResponseEntity<ApiResponse<FenceDto>> forceUpdateFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        int version = ((Number) body.get("version")).intValue();
        FenceDto fence = fenceApplicationService.forceUpdateFence(fenceId,
                parseVertices(body.get("vertices")),
                (String) body.get("name"),
                (String) body.get("color"),
                (String) body.get("shape"),
                version);
        return ResponseEntity.ok(ApiResponse.ok(fence));
    }

    /**
     * DELETE /fences/{fenceId}?deleteAlerts=true|false (default false).
     * false keeps alert rows and only detaches them from the fence;
     * true removes the fence's alert history along with it.
     */
    @DeleteMapping("/{fenceId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deleteFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            @RequestParam(name = "deleteAlerts", defaultValue = "false") boolean deleteAlerts) {
        verifyFarmOwnership(farmId);
        int deletedAlerts = fenceApplicationService.deleteFence(fenceId, deleteAlerts);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("deletedAlerts", deletedAlerts)));
    }

    /**
     * Optional creation-time metadata. Parsed leniently: a non-Map value is
     * ignored (debug log) rather than rejected, keeping create tolerant.
     * PUT /fences/{id} and /force deliberately do NOT parse this key so
     * edits preserve the stored metadata.
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> parseGenerationMetadata(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Map) {
            return (Map<String, Object>) value;
        }
        log.debug("Ignoring non-Map generationMetadata of type {}", value.getClass().getSimpleName());
        return null;
    }

    /**
     * Track-draft deviceIds: must be a JSON array of numbers; anything else
     * (missing key, wrong shape, non-numeric entry) is a 400.
     */
    private List<Long> parseDeviceIds(Object value) {
        if (!(value instanceof List<?> list)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftTooManyDevices");
        }
        List<Long> ids = new java.util.ArrayList<>(list.size());
        for (Object item : list) {
            if (!(item instanceof Number n)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftTooManyDevices");
            }
            ids.add(n.longValue());
        }
        return ids;
    }

    /**
     * Track-draft timestamps arrive as ISO-8601 strings with offset
     * (e.g. "2026-10-29T00:00:00+08:00"); a bare UTC "Z" form is accepted
     * too. Unparseable input is a client error, not a 500.
     */
    private static Instant parseTrackDraftInstant(Object value) {
        if (!(value instanceof String s) || s.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftRangeTooLong");
        }
        try {
            return OffsetDateTime.parse(s.trim()).toInstant();
        } catch (DateTimeParseException ignored) {
            // fall through to the Instant form
        }
        try {
            return Instant.parse(s.trim());
        } catch (DateTimeParseException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftRangeTooLong");
        }
    }

    @SuppressWarnings("unchecked")
    private List<GpsCoordinate> parseVertices(Object verticesObj) {
        if (verticesObj == null) return List.of();
        List<Map<String, Object>> rawList = (List<Map<String, Object>>) verticesObj;
        return rawList.stream()
                .map(m -> new GpsCoordinate(
                        toBigDecimal(m.getOrDefault("lat", m.get("latitude"))),
                        toBigDecimal(m.getOrDefault("lng", m.get("longitude")))
                ))
                .toList();
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }
}
