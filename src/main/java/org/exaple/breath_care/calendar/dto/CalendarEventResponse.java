package org.exaple.breath_care.calendar.dto;

import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.EventType;

import java.time.Instant;

public record CalendarEventResponse(
        Long id,
        String title,
        EventType eventType,
        Instant startAt,
        Instant createdAt
) {
    public static CalendarEventResponse from(CalendarEvent event) {
        return new CalendarEventResponse(
                event.getId(),
                event.getTitle(),
                event.getEventType(),
                event.getStartAt(),
                event.getCreatedAt());
    }
}
