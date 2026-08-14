package org.exaple.breath_care.session.dto;

import jakarta.validation.constraints.NotNull;
import org.exaple.breath_care.breathing.BreathingPreset;

/**
 * 세션 시작.
 *
 * @param preMeasurementId 세션 직전에 마친 측정
 * @param preset           사용할 호흡법. 추천 API가 붙기 전에는 비워도 된다
 * @param calendarEventId  알림에서 시작한 경우 그 일정. 직접 시작이면 비워 둔다
 */
public record SessionStartRequest(

        @NotNull(message = "세션 전 측정 id는 필수입니다.")
        Long preMeasurementId,

        BreathingPreset preset,

        Long calendarEventId
) {
}
