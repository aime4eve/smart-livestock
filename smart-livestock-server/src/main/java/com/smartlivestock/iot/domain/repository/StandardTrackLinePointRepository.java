package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.StandardTrackLinePoint;

import java.util.List;

public interface StandardTrackLinePointRepository {
    List<StandardTrackLinePoint> saveAll(List<StandardTrackLinePoint> points);
    List<StandardTrackLinePoint> findByLineIdOrderBySequenceNo(Long lineId);
    void deleteByLineId(Long lineId);
}
