package org.exaple.breath_care.calendar.dto;

import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.EventSource;
import org.exaple.breath_care.calendar.EventType;

import java.time.Instant;

/**
 * @param source PHONE이면 폰 캘린더에서 온 일정이다. 제목·시각을 앱에서 고쳐도
 *               다음 동기화에 되돌아가므로, 화면에서 수정을 막거나 안내하는 데 쓴다.
 *               (종류는 고쳐도 유지된다)
 */
public record CalendarEventResponse(
        Long id,
        String title,
        EventType eventType,
        Instant startAt,
        EventSource source,
        Instant createdAt
) {
    public static CalendarEventResponse from(CalendarEvent event) {
        return new CalendarEventResponse(
                event.getId(),
                event.getTitle(),
                event.getEventType(),
                event.getStartAt(),
                event.getSource(),
                event.getCreatedAt());
    }
}
