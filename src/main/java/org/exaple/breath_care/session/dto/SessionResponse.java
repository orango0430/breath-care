package org.exaple.breath_care.session.dto;

import org.exaple.breath_care.breathing.BreathingPreset;
import org.exaple.breath_care.session.BreathingSession;

import java.time.Instant;

/**
 * 세션 결과. 아직 끝나지 않은 세션은 after·change가 비어 있다.
 *
 * <p>값은 반올림하지 않은 원본이다. 화면에 표시할 때만 심박수·스트레스 지수를 5단위로 끊는다.
 */
public record SessionResponse(
        Long id,
        BreathingPreset preset,
        Long calendarEventId,
        Instant startedAt,
        Instant endedAt,
        MetricSnapshot before,
        MetricSnapshot after,
        MetricChange change
) {
    public static SessionResponse of(BreathingSession session, MetricSnapshot before, MetricSnapshot after) {
        return new SessionResponse(
                session.getId(),
                session.getPreset(),
                session.getCalendarEventId(),
                session.getStartedAt(),
                session.getEndedAt(),
                before,
                after,
                after == null ? null : MetricChange.between(before, after));
    }
}
