package com.ai.openapi.device.service;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.response.OpenApiResponse;
import com.ai.openapi.device.adapter.DeviceAdapter;
import com.ai.openapi.device.client.DeviceControlClient;
import com.ai.openapi.device.client.DeviceHistoryDataClient;
import com.ai.openapi.device.client.DeviceLicenseClient;
import com.ai.openapi.device.client.DeviceServiceClient;
import com.ai.openapi.device.dto.external.*;
import com.ai.openapi.device.dto.internal.*;
import com.ai.openapi.device.dto.TimeFormatLocale;
import com.ai.openapi.common.dto.LoginUser;
import com.ai.openapi.space.service.SpaceBffService;
import feign.FeignException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class DeviceBffService {

    private final DeviceServiceClient deviceServiceClient;
    private final DeviceControlClient deviceControlClient;
    private final DeviceLicenseClient deviceLicenseClient;
    private final DeviceHistoryDataClient deviceHistoryDataClient;
    private final DeviceAdapter deviceAdapter;
    private final SpaceBffService spaceBffService;

    public DeviceBffService(DeviceServiceClient deviceServiceClient,
                            DeviceControlClient deviceControlClient,
                            DeviceLicenseClient deviceLicenseClient,
                            DeviceHistoryDataClient deviceHistoryDataClient,
                            DeviceAdapter deviceAdapter,
                            SpaceBffService spaceBffService) {
        this.deviceServiceClient = deviceServiceClient;
        this.deviceControlClient = deviceControlClient;
        this.deviceLicenseClient = deviceLicenseClient;
        this.deviceHistoryDataClient = deviceHistoryDataClient;
        this.deviceAdapter = deviceAdapter;
        this.spaceBffService = spaceBffService;
    }

    public OpenApiResponse<DeviceVO> listDevices(String keyword, String spaceId, int page, int pageSize) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        DevicePageReq req = new DevicePageReq();
        req.setUserId(loginUser.getUserId());
        req.setKeyword(keyword);
        req.setSpaceId(spaceId);
        req.setCurrent(page);
        req.setSize(pageSize);

        InternalResponse<DevicePageResp> response = deviceServiceClient.pageDevices(req);

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "查询设备列表失败: " + response.getMsg());
        }

        DevicePageResp pageData = response.getData();
        long total = pageData != null && pageData.getTotal() != null ? pageData.getTotal() : 0;
        List<DeviceDetailResp> records = pageData != null && pageData.getRecords() != null
                ? pageData.getRecords() : List.of();

        List<DeviceVO> items = deviceAdapter.toExternalList(records);
        return OpenApiResponse.of(items, total, page, pageSize);
    }

    public DeviceDetailVO getDeviceDetail(String deviceId) {
        DeviceDetailReq req = new DeviceDetailReq();
        req.setDeviceId(deviceId);

        InternalResponse<DeviceDetailResp> response = deviceServiceClient.getDeviceDetail(req);

        if (!response.isOk() || response.getData() == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "设备不存在: " + (response.getMsg() != null ? response.getMsg() : ""));
        }

        return deviceAdapter.toDetailExternal(response.getData());
    }

    public RegisterDeviceResponse registerDevice(RegisterDeviceRequest request) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        // 1. 查询 License
        InternalResponse<LicenseStatusResp> licenseResp;
        try {
            licenseResp = deviceLicenseClient.getLicenseStatusBySn(request.getSn());
        } catch (FeignException e) {
            log.error("License 服务调用失败: sn={}, status={}", request.getSn(), e.status(), e);
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "License 服务暂时不可用");
        }
        if (!licenseResp.isOk() || licenseResp.getData() == null) {
            throw new OpenApiException(ErrorCode.INVALID_SN.getHttpStatus(), ErrorCode.INVALID_SN.getCode(),
                    "SN 不存在或 License 服务异常");
        }

        LicenseStatusResp license = licenseResp.getData();
        if (license.getIsValid() == null || !license.getIsValid()) {
            throw new OpenApiException(ErrorCode.INVALID_SN.getHttpStatus(), ErrorCode.INVALID_SN.getCode(),
                    "SN 未激活或已失效");
        }

        // 2. 校验空间
        if (request.getSpaceId() != null && !request.getSpaceId().isEmpty()) {
            try {
                spaceBffService.getSpaceDetail(request.getSpaceId());
            } catch (OpenApiException e) {
                if (ErrorCode.NOT_FOUND.getCode().equals(e.getErrorCode())) {
                    throw new OpenApiException(ErrorCode.INVALID_SPACE.getHttpStatus(),
                            ErrorCode.INVALID_SPACE.getCode(), "spaceId 对应的空间不存在");
                }
                throw e;
            }
        }

        // 3. 注册设备
        DeviceRegistrationReq regReq = new DeviceRegistrationReq();
        regReq.setUser(loginUser);
        regReq.setDeviceIdentifier(license.getDeviceEui());
        regReq.setDeviceTypeCode(license.getDeviceTypeCode());
        regReq.setSpaceId(request.getSpaceId());

        InternalResponse<DeviceRegistrationResp> regResp = deviceServiceClient.registerDevice(regReq);
        if (!regResp.isOk() || regResp.getData() == null) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "注册设备失败: " + regResp.getMsg());
        }

        DeviceRegistrationResp regResult = regResp.getData();
        String deviceId = regResult.getDeviceId();

        // 4. 绑定空间
        if (request.getSpaceId() != null && !request.getSpaceId().isEmpty()) {
            spaceBffService.createDeviceBinding(request.getSpaceId(), deviceId);
        }

        // 5. 更新设备名称
        if (request.getName() != null && !request.getName().isEmpty()) {
            DeviceUpdateReq updateReq = new DeviceUpdateReq();
            updateReq.setUser(loginUser);
            updateReq.setDeviceId(deviceId);
            updateReq.setDeviceName(request.getName());
            deviceServiceClient.updateDeviceInfo(updateReq);
        }

        // 6. 返回结果
        RegisterDeviceResponse resp = new RegisterDeviceResponse();
        resp.setDevice_id(deviceId);
        resp.setType(license.getDeviceTypeCode());
        resp.setName(request.getName() != null ? request.getName() : regResult.getDeviceTypeId());
        resp.setStatus(regResult.getStatus());
        resp.setCreated_at(regResult.getCreateTime());
        return resp;
    }

    public boolean deleteDevice(String deviceId) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        DeviceRemoveReq req = new DeviceRemoveReq();
        req.setUser(loginUser);
        req.setDeviceIds(List.of(deviceId));

        InternalResponse<Boolean> response = deviceServiceClient.removeDevice(req);

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "删除设备失败: " + response.getMsg());
        }

        return Boolean.TRUE.equals(response.getData());
    }

    public DeviceVO updateDevice(String deviceId, UpdateDeviceRequest request) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        DeviceUpdateReq req = new DeviceUpdateReq();
        req.setUser(loginUser);
        req.setDeviceId(deviceId);
        req.setDeviceName(request.getName());

        InternalResponse<Boolean> response = deviceServiceClient.updateDeviceInfo(req);

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "修改设备信息失败: " + response.getMsg());
        }

        DeviceVO vo = new DeviceVO();
        vo.setDevice_id(deviceId);
        vo.setName(request.getName());
        return vo;
    }

    /**
     * 查询设备历史数据（分页），对接 {@code /feign/v1/device/history/data/query-list-page/{deviceId}}。
     */
    public OpenApiResponse<Map<String, Object>> queryDeviceHistoryData(
            String deviceId, String startTime, String endTime, int page, int pageSize, String locale) {

        TimeFormatLocale timeFormat = TimeFormatLocale.fromHeader(locale);
        timeFormat.validate("start_time", startTime);
        timeFormat.validate("end_time", endTime);

        String upstreamStartTime = timeFormat.convertToUpstreamFormat(startTime);
        String upstreamEndTime = timeFormat.convertToUpstreamFormat(endTime);

        DeviceHistoryDataPageReq req = new DeviceHistoryDataPageReq();
        req.setStartTime(upstreamStartTime);
        req.setEndTime(upstreamEndTime);
        req.setCurrent(page);
        req.setSize(pageSize);

        InternalResponse<DeviceHistoryDataPageResp> response = deviceHistoryDataClient.queryHistoryDataPage(deviceId, req);

        if (!response.isOk() || response.getData() == null) {
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "查询设备历史数据失败: " + response.getMsg());
        }

        DeviceHistoryDataPageResp data = response.getData();
        List<Map<String, Object>> records = data.getRecords() != null ? data.getRecords() : List.of();
        long total = data.getTotal() != null ? data.getTotal() : 0;
        return OpenApiResponse.of(records, total, page, pageSize);
    }

    /**
     * 查询子设备历史数据（分页），对接 {@code /feign/v1/device/history/data/query-sub-device-list-page/{subDeviceId}}。
     */
    public OpenApiResponse<Map<String, Object>> querySubDeviceHistoryData(
            String subDeviceId, String startTime, String endTime, int page, int pageSize, String locale) {

        TimeFormatLocale timeFormat = TimeFormatLocale.fromHeader(locale);
        timeFormat.validate("start_time", startTime);
        timeFormat.validate("end_time", endTime);

        String upstreamStartTime = timeFormat.convertToUpstreamFormat(startTime);
        String upstreamEndTime = timeFormat.convertToUpstreamFormat(endTime);

        DeviceHistoryDataPageReq req = new DeviceHistoryDataPageReq();
        req.setStartTime(upstreamStartTime);
        req.setEndTime(upstreamEndTime);
        req.setCurrent(page);
        req.setSize(pageSize);

        InternalResponse<DeviceHistoryDataPageResp> response =
                deviceHistoryDataClient.querySubDeviceHistoryDataPage(subDeviceId, req);

        if (!response.isOk() || response.getData() == null) {
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "查询子设备历史数据失败: " + response.getMsg());
        }

        DeviceHistoryDataPageResp data = response.getData();
        List<Map<String, Object>> records = data.getRecords() != null ? data.getRecords() : List.of();
        long total = data.getTotal() != null ? data.getTotal() : 0;
        return OpenApiResponse.of(records, total, page, pageSize);
    }

    /**
     * 业务指令下发，对接设备服务 {@code /feign/v1/device/control/businessCmdDown}。
     */
    public SendDeviceCommandResponse sendDeviceCommand(String deviceId, SendDeviceCommandRequest body) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());
        if (ctx.getKeyExternalId() != null && !ctx.getKeyExternalId().isEmpty()) {
            loginUser.setUserName(ctx.getKeyExternalId());
        } else {
            loginUser.setUserName("open-api");
        }

        DeviceDetailReq existence = new DeviceDetailReq();
        existence.setDeviceId(deviceId);
        InternalResponse<DeviceDetailResp> detailResp = deviceServiceClient.getDeviceDetail(existence);
        if (!detailResp.isOk() || detailResp.getData() == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "设备不存在: " + (detailResp.getMsg() != null ? detailResp.getMsg() : ""));
        }

        BusinessCmdDownReq req = new BusinessCmdDownReq();
        req.setUser(loginUser);
        req.setRequestId(null);
        req.setDeviceId(deviceId);
        req.setSubDeviceIds(body.getSubDeviceIds());
        req.setTriggerSource("OPEN_API");

        DeviceControlFunctionDto funcDto = new DeviceControlFunctionDto();
        funcDto.setMethod(body.getFunc().getMethod());
        funcDto.setParams(body.getFunc().getParams());
        req.setFunc(funcDto);
        req.setDownConfig(defaultDownConfig());

        InternalResponse<BatchCmdDownResp> resp;
        try {
            resp = deviceControlClient.businessCmdDown(req);
        } catch (FeignException e) {
            log.error("businessCmdDown Feign 失败: deviceId={}, status={}", deviceId, e.status(), e);
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "设备指令下发调用失败");
        }

        if (!resp.isOk() || resp.getData() == null) {
            String msg = resp.getMsg() != null ? resp.getMsg() : "指令下发失败";
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), msg);
        }

        return toBatchCommandResponse(resp.getData());
    }

    private SendDeviceCommandResponse toBatchCommandResponse(BatchCmdDownResp batch) {
        SendDeviceCommandResponse out = new SendDeviceCommandResponse();
        if (batch == null) {
            return out;
        }
        out.setTotal_count(batch.getTotalCount());
        out.setSuccess_count(batch.getSuccessCount());
        out.setFail_count(batch.getFailCount());
        if (batch.getSuccessList() != null) {
            List<DeviceCommandSuccessItem> ok = new ArrayList<>();
            for (CmdDownResp s : batch.getSuccessList()) {
                if (s == null) {
                    continue;
                }
                DeviceCommandSuccessItem i = new DeviceCommandSuccessItem();
                i.setRecord_id(s.getRecordId());
                i.setCommand_status(s.getCmdDownStatus());
                i.setError_message(s.getErrorMsg());
                ok.add(i);
            }
            out.setSuccess_list(ok);
        }
        if (batch.getFailList() != null) {
            List<DeviceCommandFailureItem> fl = new ArrayList<>();
            for (CmdDownFailureItem f : batch.getFailList()) {
                if (f == null) {
                    continue;
                }
                DeviceCommandFailureItem i = new DeviceCommandFailureItem();
                i.setDevice_id(f.getDeviceId());
                i.setEnqueue(f.getEnqueue());
                i.setWait_for_response(f.getWaitForResponse());
                i.setFunc(f.getFunc());
                i.setError_message(f.getErrorMsg());
                fl.add(i);
            }
            out.setFail_list(fl);
        }
        return out;
    }

    /** 下行配置由服务端固定，不对调用方开放 */
    private CmdDownConfigDto defaultDownConfig() {
        CmdDownConfigDto dto = new CmdDownConfigDto();
        dto.setResponseTimeout(30);
        dto.setRetryTimes(3);
        dto.setRetryInterval(5);
        dto.setTryAgainImmediately(Boolean.TRUE);
        return dto;
    }

    /**
     * 查询设备遥测数据，对接 {@code /feign/v1/device/lifecycle/getDeviceDetailWithTelemetry}。
     */
    public DeviceTelemetryVO getDeviceTelemetry(String deviceId) {
        InternalResponse<DeviceTelemetryResp> response = deviceServiceClient.getDeviceDetailWithTelemetry(deviceId);

        if (!response.isOk() || response.getData() == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "设备不存在: " + (response.getMsg() != null ? response.getMsg() : ""));
        }

        return deviceAdapter.toTelemetryExternal(response.getData());
    }

    /**
     * 查询单条控制记录状态，对接 {@code /feign/v1/device/control/record/queryControlRecordByIds}。
     */
    public DeviceCommandStatusVO getCommandStatus(String commandId) {
        InternalResponse<List<DeviceControlRecordRespDto>> resp;
        try {
            resp = deviceControlClient.queryControlRecordByIds(List.of(commandId));
        } catch (FeignException e) {
            log.error("queryControlRecordByIds Feign 失败: commandId={}, status={}", commandId, e.status(), e);
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "查询命令状态失败");
        }

        if (!resp.isOk() || resp.getData() == null || resp.getData().isEmpty()) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "命令记录不存在");
        }

        List<DeviceControlRecordRespDto> rows = resp.getData();
        DeviceControlRecordRespDto row = rows.size() == 1
                ? rows.get(0)
                : rows.stream()
                .filter(r -> r != null && commandId.equals(r.getId()))
                .findFirst()
                .orElse(null);

        if (row == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "命令记录不存在");
        }

        DeviceCommandStatusVO vo = new DeviceCommandStatusVO();
        vo.setRecord_id(row.getId());
        vo.setDevice_id(row.getDeviceId());
        vo.setTrigger_source(row.getTriggerSource());
        vo.setTrigger_source_text(row.getTriggerSourceText());
        vo.setFunc_name(row.getFuncName());
        vo.setFunc_params(row.getFuncParams());
        vo.setCmd_state(row.getCmdState());
        vo.setCmd_state_text(row.getCmdStateText());
        vo.setError_msg(row.getErrorMsg());
        vo.setCreate_time(row.getCreateTime());
        vo.setOperator_name(row.getOperatorName());
        return vo;
    }
}
