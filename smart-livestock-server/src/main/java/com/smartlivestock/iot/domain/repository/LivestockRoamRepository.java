package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.LivestockRoamDaily;

import java.time.LocalDate;
import java.util.List;

public interface LivestockRoamRepository {

    /** Upsert the daily aggregate of one device. */
    LivestockRoamDaily save(LivestockRoamDaily aggregate);

    List<LivestockRoamDaily> findByDeviceBetween(Long deviceId, LocalDate from, LocalDate to);
}
