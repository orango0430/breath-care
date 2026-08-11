package org.exaple.breath_care.calendar.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.exaple.breath_care.calendar.EventType;

import java.time.Instant;

/**
 * 일정 등록·수정 요청. 등록과 수정이 같은 필드를 쓰므로 하나로 둔다.
 *
 * @param startAt 오프셋 포함 ISO-8601. 예) 2026-08-15T14:00:00+09:00
 */
public record CalendarEventRequest(

        @NotBlank(message = "일정명은 필수입니다.")
        @Size(max = 255, message = "일정명은 255자 이하여야 합니다.")
        String title,

        @NotNull(message = "일정 종류는 필수입니다.")
        EventType eventType,

        @NotNull(message = "일정 시각은 필수입니다.")
        Instant startAt
) {
}
