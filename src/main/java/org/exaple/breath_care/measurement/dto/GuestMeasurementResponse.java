package org.exaple.breath_care.measurement.dto;

import org.exaple.breath_care.measurement.MeasurementQuality;

import java.time.Instant;

/**
 * 비회원 측정 결과.
 *
 * <p>회원 응답과 달리 <b>id가 없다.</b> 저장하지 않았으니 가리킬 대상도 없다.
 * 이 결과를 다음 기준선에 반영하려면 앱이 hr을 자기 이력에 넣어 두어야 한다.
 *
 * @param hrv         품질이 낮으면 null
 * @param stressScore 0~100, <b>높을수록 긴장도가 높다</b>. 기준선이 없으면 null
 * @param baseline    기준선 상태. 점수가 null인 이유를 앱이 설명하는 데 쓴다
 */
public record GuestMeasurementResponse(
        Double hr,
        Double hrv,
        Double stressScore,
        MeasurementQuality quality,
        Instant measuredAt,
        BaselineResponse baseline
) {
}
