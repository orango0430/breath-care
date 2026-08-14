package org.exaple.breath_care.calendar.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

/**
 * 폰 캘린더 동기화. 앱이 구간을 정해 훑고, 그 구간의 일정을 통째로 보낸다.
 *
 * <p><b>from·to는 "앱이 실제로 훑은 범위"다.</b> 서버는 이 구간 안에서만 일정을 지운다.
 * 구간을 받지 않고 지우면, 앱이 한 달치만 읽어 왔을 때 나머지 기간의 일정이 전부 사라진다.
 *
 * @param events 구간 안의 폰 일정 전부. 비어 있으면 그 구간의 폰 일정을 모두 지운다는 뜻이다
 */
public record CalendarSyncRequest(

        @NotNull(message = "동기화 시작 시각은 필수입니다.")
        Instant from,

        @NotNull(message = "동기화 종료 시각은 필수입니다.")
        Instant to,

        @NotNull(message = "events는 필수입니다. 빈 배열은 허용됩니다.")
        @Size(max = 1000, message = "한 번에 동기화할 수 있는 일정은 1000개까지입니다.")
        List<@Valid @NotNull SyncedEvent> events
) {
}
