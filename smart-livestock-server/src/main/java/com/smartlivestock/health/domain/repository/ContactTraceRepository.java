package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.ContactTrace;

import java.util.List;

public interface ContactTraceRepository {
    List<ContactTrace> findByFarmIdOrderByLastContactAtDesc(Long farmId);
    ContactTrace save(ContactTrace trace);
}
