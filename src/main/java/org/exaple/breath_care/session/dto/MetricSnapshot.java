package org.exaple.breath_care.session.dto;

import org.exaple.breath_care.measurement.Measurement;

/** 한 시점의 세 지표. */
public record MetricSnapshot(Double hr, Double hrv, Double conditionScore) {

    public static MetricSnapshot from(Measurement measurement) {
        return new MetricSnapshot(
                measurement.getHr(), measurement.getHrv(), measurement.getConditionScore());
    }
}
