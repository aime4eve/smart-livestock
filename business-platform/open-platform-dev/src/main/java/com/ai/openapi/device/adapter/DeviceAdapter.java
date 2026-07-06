package com.ai.openapi.device.adapter;

import com.ai.openapi.common.util.DateUtil;
import com.ai.openapi.device.dto.external.DeviceDetailVO;
import com.ai.openapi.device.dto.external.DeviceTelemetryVO;
import com.ai.openapi.device.dto.external.DeviceVO;
import com.ai.openapi.device.dto.internal.DeviceDetailResp;
import com.ai.openapi.device.dto.internal.DeviceTelemetryResp;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DeviceAdapter {

    public DeviceVO toExternal(DeviceDetailResp internal) {
        if (internal == null) {
            return null;
        }
        DeviceVO vo = new DeviceVO();
        vo.setDevice_id(internal.getDeviceId());
        vo.setName(internal.getDeviceName());
        vo.setType(internal.getDeviceTypeCode());
        vo.setType_name(internal.getDeviceTypeName());
        vo.setStatus(internal.getOnlineStatusName());
        vo.setStatus_code(internal.getOnlineStatus());
        vo.setCreated_at(DateUtil.toIso8601(internal.getCreateTime()));
        vo.setLast_active_at(DateUtil.toIso8601(internal.getLastActiveTime()));
        return vo;
    }

    public DeviceDetailVO toDetailExternal(DeviceDetailResp internal) {
        if (internal == null) {
            return null;
        }
        DeviceDetailVO vo = new DeviceDetailVO();
        vo.setDevice_id(internal.getDeviceId());
        vo.setName(internal.getDeviceName());
        vo.setIdentifier(internal.getDeviceIdentifier());
        vo.setType(internal.getDeviceTypeCode());
        vo.setType_name(internal.getDeviceTypeName());
        vo.setType_id(internal.getDeviceTypeId());
        vo.setStatus(internal.getOnlineStatusName());
        vo.setStatus_code(internal.getOnlineStatus());
        vo.setControl_enabled(internal.getControlEnabled() != null && internal.getControlEnabled() == 1);
        vo.setData_collection_enabled(internal.getDataCollectionEnabled() != null && internal.getDataCollectionEnabled() == 1);
        vo.setCreated_at(DateUtil.toIso8601(internal.getCreateTime()));
        vo.setLast_active_at(DateUtil.toIso8601(internal.getLastActiveTime()));
        vo.setRssi(internal.getRssi());
        vo.setSnr(internal.getSnr());
        vo.setSpreading_factor(internal.getSf());
        vo.setLast_gateway(internal.getLastGateway());
        return vo;
    }

    public List<DeviceVO> toExternalList(List<DeviceDetailResp> internals) {
        if (internals == null) {
            return List.of();
        }
        return internals.stream().map(this::toExternal).toList();
    }

    public DeviceTelemetryVO toTelemetryExternal(DeviceTelemetryResp internal) {
        if (internal == null) {
            return null;
        }
        DeviceTelemetryVO vo = new DeviceTelemetryVO();
        vo.setDevice_id(internal.getDeviceId());
        vo.setName(internal.getDeviceName());
        vo.setIdentifier(internal.getDeviceIdentifier());
        vo.setType_id(internal.getDeviceTypeId());
        vo.setType_name(internal.getDeviceTypeName());
        vo.setType(internal.getDeviceTypeCode());
        vo.setOnline_status(internal.getOnlineStatus());
        vo.setOnline_status_name(internal.getOnlineStatusName());
        vo.setLast_active_at(DateUtil.toIso8601(internal.getLastActiveTime()));
        vo.setControl_enabled(internal.getIsControlEnabled() != null && internal.getIsControlEnabled() == 1);
        vo.setData_collection_enabled(internal.getIsDataCollectionEnabled() != null && internal.getIsDataCollectionEnabled() == 1);
        vo.setRssi(internal.getRssi());
        vo.setSnr(internal.getSnr());
        vo.setSpreading_factor(internal.getSf());
        vo.setLast_gateway(internal.getLastGateway());
        vo.setTelemetry_properties(toTelemetryPropertyVOList(internal.getTelemetryProperties()));
        vo.setSub_devices(toSubDeviceTelemetryVOList(internal.getSubDevices()));
        return vo;
    }

    private List<DeviceTelemetryVO.TelemetryPropertyVO> toTelemetryPropertyVOList(
            List<DeviceTelemetryResp.TelemetryPropertyDto> properties) {
        if (properties == null) {
            return null;
        }
        return properties.stream().map(p -> {
            DeviceTelemetryVO.TelemetryPropertyVO vo = new DeviceTelemetryVO.TelemetryPropertyVO();
            vo.setIdentifier(p.getIdentifier());
            vo.setName(p.getName());
            vo.setData_type(p.getDataType());
            vo.setSpecs(p.getSpecs());
            vo.setDescription(p.getDescription());
            vo.setValue(p.getValue());
            return vo;
        }).toList();
    }

    private List<DeviceTelemetryVO.SubDeviceTelemetryVO> toSubDeviceTelemetryVOList(
            List<DeviceTelemetryResp.SubDeviceTelemetryResp> subDevices) {
        if (subDevices == null) {
            return null;
        }
        return subDevices.stream().map(s -> {
            DeviceTelemetryVO.SubDeviceTelemetryVO vo = new DeviceTelemetryVO.SubDeviceTelemetryVO();
            vo.setSub_device_id(s.getSubDeviceId());
            vo.setSub_device_name(s.getSubDeviceName());
            vo.setSub_device_identifier(s.getSubDeviceIdentifier());
            vo.setDevice_type_id(s.getDeviceTypeId());
            vo.setLast_active_at(DateUtil.toIso8601(s.getLastActiveTime()));
            vo.setTelemetry_properties(toTelemetryPropertyVOList(s.getTelemetryProperties()));
            return vo;
        }).toList();
    }
}
