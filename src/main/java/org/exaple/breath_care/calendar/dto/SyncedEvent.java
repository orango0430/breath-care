package org.exaple.breath_care.calendar.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/**
 * 폰 캘린더에서 읽어 온 일정 하나.
 *
 * <p>일정 종류는 받지 않는다. 폰 캘린더에는 그 정보가 없고, 제목으로 추측하면
 * "김교수님 수업 PT"처럼 키워드가 없거나 엉뚱한 경우가 많다. 사용자가 앱에서 고르면 채워진다.
 *
 * @param externalId 폰 캘린더가 매긴 id. 같은 일정을 다시 알아보는 유일한 열쇠라 필수다
 * @param startAt    일정 시각. 오프셋 포함 ISO-8601로 보내면 서버가 UTC로 저장한다
 */
public record SyncedEvent(

        @NotBlank(message = "externalId는 필수입니다.")
        @Size(max = 255, message = "externalId가 너무 깁니다.")
        String externalId,

        @NotBlank(message = "일정명은 필수입니다.")
        @Size(max = 255, message = "일정명이 너무 깁니다.")
        String title,

        @NotNull(message = "일정 시각은 필수입니다.")
        Instant startAt
) {
}
