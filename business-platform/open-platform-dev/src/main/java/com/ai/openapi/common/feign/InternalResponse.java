package com.ai.openapi.common.feign;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class InternalResponse<T> {

    private int code;
    private boolean success;
    private T data;
    private String msg;

    public boolean isOk() {
        return success && (code == 200 || code == 0);
    }

    public static <T> InternalResponse<T> ok(T data) {
        InternalResponse<T> resp = new InternalResponse<>();
        resp.setCode(200);
        resp.setSuccess(true);
        resp.setData(data);
        resp.setMsg("操作成功");
        return resp;
    }

    public static <T> InternalResponse<T> fail(String msg) {
        InternalResponse<T> resp = new InternalResponse<>();
        resp.setCode(500);
        resp.setSuccess(false);
        resp.setMsg(msg);
        return resp;
    }
}
