package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.AnomalyPattern;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Ground-truth label CRUD service.
 *
 * saveLabel uses REQUIRES_NEW propagation (design §8A / P1 #8): label writes
 * are decoupled from the batch ingest loop in SynthesisService.generate(),
 * which itself has no @Transactional.
 *
 * createManualLabel is reserved for Phase C annotation infrastructure (#56).
 */
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

    // Reserved for Phase C (#56) — not wired in Phase B UI
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public GroundTruthLabel createManualLabel(Long livestockId, AnomalyPattern pattern,
                                               Instant start, Instant end,
                                               Long labeledBy, String note) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setPattern(pattern);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.MANUAL);
        label.setLabeledBy(labeledBy);
        label.setLabeledAt(Instant.now());
        label.setNote(note);
        return repository.save(label);
    }
}
