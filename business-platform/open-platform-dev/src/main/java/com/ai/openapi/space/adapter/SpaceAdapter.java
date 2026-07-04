package com.ai.openapi.space.adapter;

import com.ai.openapi.common.util.DateUtil;
import com.ai.openapi.space.dto.external.SpaceVO;
import com.ai.openapi.space.dto.internal.SpaceNodeVO;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SpaceAdapter {

    public SpaceVO toExternal(SpaceNodeVO internal) {
        if (internal == null) {
            return null;
        }
        SpaceVO vo = new SpaceVO();
        vo.setSpace_id(internal.getNodeId());
        vo.setName(internal.getName());
        vo.setParent_id(internal.getParentId());
        vo.setRoot_id(internal.getRootId());
        vo.setCreated_at(DateUtil.toIso8601(internal.getCreatedAt()));
        return vo;
    }

    public List<SpaceVO> toExternalList(List<SpaceNodeVO> internals) {
        if (internals == null) {
            return List.of();
        }
        return internals.stream().map(this::toExternal).toList();
    }
}
