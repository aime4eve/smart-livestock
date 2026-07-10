package com.ai.openapi.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class OpenApiResponse<T> {

    private List<T> data;
    private Long total;
    /** 当前页，从 1 开始 */
    private Integer page;
    private Integer pageSize;

    public static <T> OpenApiResponse<T> of(List<T> data, long total, int page, int pageSize) {
        OpenApiResponse<T> response = new OpenApiResponse<>();
        response.setData(data);
        response.setTotal(total);
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    public static <T> OpenApiResponse<T> of(List<T> data, long total) {
        return of(data, total, 1, 20);
    }
}
