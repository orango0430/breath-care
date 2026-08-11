package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;

/**
 * 신호처리 결과.
 *
 * @param hr      분당 심박수. 품질이 POOR이면 의미 없다.
 * @param hrv     RMSSD(ms). 품질이 낮으면 null.
 * @param quality 품질 게이트 판정
 */
public record SignalResult(Double hr, Double hrv, MeasurementQuality quality) {

    public static SignalResult poor() {
        return new SignalResult(null, null, MeasurementQuality.POOR);
    }

    public boolean isUsable() {
        return quality != MeasurementQuality.POOR;
    }
}
