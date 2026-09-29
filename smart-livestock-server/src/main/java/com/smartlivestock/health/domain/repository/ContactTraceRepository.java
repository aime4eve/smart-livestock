package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.ContactTrace;

import java.util.List;

public interface ContactTraceRepository {
    List<ContactTrace> findByFarmIdOrderByLastContactAtDesc(Long farmId);
    List<ContactTrace> findByFromLivestockIdOrderByLastContactAtDesc(Long fromLivestockId);

    /**
     * All rows of a farm in which the livestock participates on either side
     * (from or to). The kernel normalizes pair direction to min(id)=from, so a
     * marked source holding the larger id appears on the {@code to} side; the
     * mark-diseased flow needs both sides to claim the whole contact row set.
     */
    List<ContactTrace> findByFarmIdAndLivestockParticipation(Long farmId, Long livestockId);

    /**
     * Whether the farm has at least one contact row already marked as a
     * disease source ({@code markedAt} set). Feeds the overview scene card's
     * unmarked-source hint without loading the full trace list.
     */
    boolean existsMarkedSourceByFarmId(Long farmId);

    ContactTrace save(ContactTrace trace);
}
