package org.exaple.breath_care.measurement.dto;

import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementQuality;

import java.time.Instant;

/**
 * 측정 결과.
 *
 * <p>값은 반올림하지 않은 원본이다. 화면에 표시할 때는 허위 정밀도를 피하기 위해
 * 심박수는 5단위, 컨디션 지수는 10단위로 끊어서 보여준다.
 *
 * @param hrv            품질이 낮으면 null
 * @param conditionScore 0~100, 높을수록 좋음. 개인 baseline이 쌓이기 전에는 null
 */
public record MeasurementResponse(
        Long id,
        Double hr,
        Double hrv,
        Double conditionScore,
        MeasurementQuality quality,
        Instant measuredAt
) {
    public static MeasurementResponse from(Measurement measurement) {
        return new MeasurementResponse(
                measurement.getId(),
                measurement.getHr(),
                measurement.getHrv(),
                measurement.getConditionScore(),
                measurement.getQuality(),
                measurement.getMeasuredAt());
    }
}
