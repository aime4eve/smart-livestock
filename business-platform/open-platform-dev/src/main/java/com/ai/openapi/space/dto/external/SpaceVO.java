package com.ai.openapi.space.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SpaceVO {

    private String space_id;
    private String name;
    private String parent_id;
    private String root_id;
    private String created_at;
}
