package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GroundTruthLabelService {

    private final GroundTruthLabelRepository repository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public GroundTruthLabel saveLabel(GroundTruthLabel label) {
        return repository.save(label);
    }

    public List<GroundTruthLabel> findByLivestockAndPeriod(Long livestockId, Instant from, Instant to) {
        return repository.findByLivestockIdAndPeriodOverlap(livestockId, from, to);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public GroundTruthLabel createManualLabel(Long livestockId, ScenarioType type,
                                               Instant start, Instant end, Long labeledBy, String note) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setType(type);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.MANUAL);
        label.setLabeledBy(labeledBy);
        label.setLabeledAt(Instant.now());
        label.setNote(note);
        return repository.save(label);
    }
}
