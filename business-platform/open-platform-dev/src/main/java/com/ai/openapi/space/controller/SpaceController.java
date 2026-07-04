package com.ai.openapi.space.controller;

import com.ai.openapi.common.response.OpenApiResponse;
import com.ai.openapi.common.validation.OpenApiPatterns;
import com.ai.openapi.space.dto.external.CreateSpaceRequest;
import com.ai.openapi.space.dto.external.SpaceVO;
import com.ai.openapi.space.dto.external.UpdateSpaceRequest;
import com.ai.openapi.space.service.SpaceBffService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Validated
@RestController
@RequestMapping("/v1/spaces")
public class SpaceController {

    private final SpaceBffService spaceBffService;

    public SpaceController(SpaceBffService spaceBffService) {
        this.spaceBffService = spaceBffService;
    }

    @GetMapping
    public ResponseEntity<OpenApiResponse<SpaceVO>> listSpaces(
            @RequestParam(required = false) @Size(max = 100, message = "name 长度不能超过 100") String name,
            @RequestParam(value = "parent_id", required = false)
            @Pattern(regexp = OpenApiPatterns.OPTIONAL_NUMERIC_ID, message = "parent_id 须为不超过21位的数字 ID") String parentId,
            @RequestParam(defaultValue = "1") @Min(1) @Max(1_000_000) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(200) int pageSize) {
        OpenApiResponse<SpaceVO> response = spaceBffService.listSpaces(name, parentId, page, pageSize);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{space_id}")
    public ResponseEntity<SpaceVO> getSpace(
            @PathVariable("space_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "space_id 须为 1～21 位数字 ID") String spaceId) {
        SpaceVO space = spaceBffService.getSpaceDetail(spaceId);
        return ResponseEntity.ok(space);
    }

    @PostMapping
    public ResponseEntity<SpaceVO> createSpace(@Valid @RequestBody CreateSpaceRequest request) {
        SpaceVO space = spaceBffService.createSpace(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(space);
    }

    @PutMapping("/{space_id}")
    public ResponseEntity<SpaceVO> updateSpace(
            @PathVariable("space_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "space_id 须为 1～21 位数字 ID") String spaceId,
            @Valid @RequestBody UpdateSpaceRequest request) {
        SpaceVO space = spaceBffService.updateSpace(spaceId, request);
        return ResponseEntity.ok(space);
    }

    @DeleteMapping("/{space_id}")
    public ResponseEntity<Map<String, Object>> deleteSpace(
            @PathVariable("space_id")
            @Pattern(regexp = OpenApiPatterns.NUMERIC_ID, message = "space_id 须为 1～21 位数字 ID") String spaceId) {
        boolean deleted = spaceBffService.deleteSpace(spaceId);
        return ResponseEntity.ok(Map.of("space_id", spaceId, "deleted", deleted));
    }
}
