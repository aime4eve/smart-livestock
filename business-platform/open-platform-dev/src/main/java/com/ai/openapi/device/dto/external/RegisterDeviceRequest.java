package com.ai.openapi.device.dto.external;

import com.ai.openapi.common.validation.OpenApiPatterns;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterDeviceRequest {

    @NotBlank(message = "sn 不能为空")
    @Size(max = 100, message = "sn 长度不能超过 100")
    private String sn;

    @Size(max = 100, message = "name 长度不能超过 100")
    private String name;

    @Pattern(regexp = OpenApiPatterns.OPTIONAL_NUMERIC_ID, message = "spaceId 须为不超过21位的数字 ID")
    private String spaceId;
}
