package com.ai.openapi.space.dto.external;

import com.ai.openapi.common.validation.OpenApiPatterns;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateSpaceRequest {

    @NotBlank(message = "name 不能为空")
    @Size(max = 100, message = "name 长度不能超过 100")
    private String name;

    /** 上级空间 ID；不传或空字符串表示顶级（根）空间 */
    @Pattern(regexp = OpenApiPatterns.OPTIONAL_NUMERIC_ID, message = "parent_id 须为不超过21位的数字 ID")
    private String parent_id;
}
