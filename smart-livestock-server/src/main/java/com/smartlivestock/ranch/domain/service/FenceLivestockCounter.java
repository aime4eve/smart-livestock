package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Counts livestock against fences by point-in-polygon on each animal's last
 * known GPS position. Single source shared by ranch-overview and the fence
 * list so both report the same semantics: only livestock with a GPS fix
 * inside an ACTIVE fence are counted; animals without a fix belong to no
 * fence at all.
 */
@Component
public class FenceLivestockCounter {

    public boolean hasGpsFix(Livestock livestock) {
        return livestock.getLastLatitude() != null && livestock.getLastLongitude() != null;
    }

    /**
     * Livestock currently located inside the fence polygon.
     * Returns 0 for an inactive fence.
     */
    public int countInFence(List<Livestock> livestockList, Fence fence) {
        if (!fence.isActive()) return 0;
        return (int) livestockList.stream()
                .filter(this::hasGpsFix)
                .filter(l -> fence.contains(
                        new GpsCoordinate(l.getLastLatitude(), l.getLastLongitude())))
                .count();
    }
}
