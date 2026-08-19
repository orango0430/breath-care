package org.exaple.breath_care.measurement.dto;

import org.exaple.breath_care.measurement.MeasurementQuality;

import java.time.Instant;

/**
 * 비회원 측정 결과.
 *
 * <p>회원 응답과 달리 <b>id가 없다.</b> 저장하지 않았으니 가리킬 대상도 없다.
 * 그 점만 빼면 회원과 값이 완전히 같다 — 컨디션 지수가 이번 측정의 HRV만으로
 * 나오므로 과거 이력이 있고 없고가 결과를 바꾸지 않는다.
 *
 * @param hrv            RMSSD(ms). 품질이 낮으면 null
 * @param conditionScore 0~100, <b>높을수록 좋다.</b> 품질이 낮아 HRV가 없을 때만 null
 */
public record GuestMeasurementResponse(
        Double hr,
        Double hrv,
        Double conditionScore,
        MeasurementQuality quality,
        Instant measuredAt
) {
}
