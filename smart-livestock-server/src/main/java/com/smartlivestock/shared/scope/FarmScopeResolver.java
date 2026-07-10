package com.smartlivestock.shared.scope;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

public class FarmScopeResolver {

    public Long resolve(FarmScopeType type, Long pathFarmId, Long headerFarmId) {
        return switch (type) {
            case WRITE -> resolveWrite(pathFarmId, headerFarmId);
            case READ -> resolveRead(pathFarmId, headerFarmId);
            case NONE -> null;
        };
    }

    private Long resolveWrite(Long pathFarmId, Long headerFarmId) {
        if (pathFarmId != null && headerFarmId != null) {
            throw new ApiException(ErrorCode.FARM_SCOPE_CONFLICT,
                "写操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "写操作必须通过 path /farms/{farmId}/... 指定牧场");
        }
        return pathFarmId;
    }

    private Long resolveRead(Long pathFarmId, Long headerFarmId) {
        if (pathFarmId != null && headerFarmId != null) {
            throw new ApiException(ErrorCode.FARM_SCOPE_CONFLICT,
                "读操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId != null) return pathFarmId;
        if (headerFarmId != null) return headerFarmId;
        throw new ApiException(ErrorCode.VALIDATION_ERROR,
            "读操作需要通过 path 或 header 指定牧场");
    }
}
