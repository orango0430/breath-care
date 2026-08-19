package org.exaple.breath_care.measurement.dto;

import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementQuality;

import java.time.Instant;

/**
 * 측정 결과. 화면에 쓰는 지표는 컨디션 지수·심박수·HRV 세 가지다.
 *
 * <p>값은 반올림하지 않은 원본이다. 허위 정밀도를 피하기 위해 <b>표시할 때</b> 끊어서 보여준다.
 * <ul>
 *   <li>컨디션 지수 — 5단위</li>
 *   <li>심박수 — 5단위</li>
 * </ul>
 * 통계·전후 비교는 원본으로 계산하고, 반올림은 마지막 표시 단계에서만 한다.
 *
 * @param hrv            RMSSD(ms). 품질이 낮으면 null
 * @param conditionScore 0~100, <b>높을수록 좋다.</b> 품질이 낮아 HRV가 없을 때만 null
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
