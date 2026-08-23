package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.identity.domain.model.Farm;

public interface BehaviorSubjectScopePort {
    void validate(BehaviorSubject subject, Farm farm);
}
