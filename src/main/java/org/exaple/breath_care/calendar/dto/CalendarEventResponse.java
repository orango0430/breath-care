package org.exaple.breath_care.calendar.dto;

import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.EventSource;
import org.exaple.breath_care.calendar.EventType;

import java.time.Instant;

/**
 * @param customCategory "+"로 직접 만든 카테고리 이름. 안 만들었으면 비어 있다
 * @param displayCategory 화면에 그대로 찍으면 되는 이름. customCategory가 있으면 그것,
 *                        없으면 종류의 기본 이름("시험"·"발표"…)이다.
 *                        앱이 이 분기를 다시 짤 필요가 없도록 서버가 계산해 내려준다
 * @param source          PHONE이면 폰 캘린더에서 온 일정이다. 제목·시각을 앱에서 고쳐도
 *                        다음 동기화에 되돌아가므로, 화면에서 수정을 막거나 안내하는 데 쓴다.
 *                        (종류·카테고리는 고쳐도 유지된다)
 */
public record CalendarEventResponse(
        Long id,
        String title,
        EventType eventType,
        String customCategory,
        String displayCategory,
        Instant startAt,
        boolean completed,
        Instant completedAt,
        EventSource source,
        Instant createdAt
) {
    public static CalendarEventResponse from(CalendarEvent event) {
        return new CalendarEventResponse(
                event.getId(),
                event.getTitle(),
                event.getEventType(),
                event.getCustomCategory(),
                event.displayCategory(),
                event.getStartAt(),
                event.isCompleted(),
                event.getCompletedAt(),
                event.getSource(),
                event.getCreatedAt());
    }
}
