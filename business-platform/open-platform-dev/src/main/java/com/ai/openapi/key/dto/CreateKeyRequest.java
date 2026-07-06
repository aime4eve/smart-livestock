package com.ai.openapi.key.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateKeyRequest {

    @Size(max = 100, message = "description 长度不能超过 100")
    private String description;

    @NotBlank(message = "scope 不能为空")
    @Pattern(regexp = "read|write|read_write|admin", message = "scope 必须为 read、write、read_write 或 admin")
    private String scope;

    @Min(value = 1, message = "expires_in_days 最小为 1")
    @Max(value = 3650, message = "expires_in_days 最大为 3650")
    private Integer expires_in_days;
}
