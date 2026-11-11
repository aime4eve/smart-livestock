package com.smartlivestock.datagen.domain.model;

/**
 * Origin of a ground-truth label. SYNTHETIC rows come from the datagen
 * pipeline, MANUAL rows from human entry. BREEDING_DERIVED (NIX-286 contract
 * v2) rows are weak evidence auto-derived from a breeding record (window:
 * breedingAt − 48h .. breedingAt); they carry no verdict and their weight in
 * calibration must NOT be treated as equal to MANUAL rulings.
 */
public enum LabelSource {
    SYNTHETIC, MANUAL, BREEDING_DERIVED
}
