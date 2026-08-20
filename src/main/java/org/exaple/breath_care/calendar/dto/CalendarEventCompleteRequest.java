package org.exaple.breath_care.calendar.dto;

import jakarta.validation.constraints.NotNull;

/**
 * 일정 완료 체크.
 *
 * <p>토글이 아니라 원하는 상태를 그대로 받는다. 토글이면 요청이 두 번 전달됐을 때
 * 체크가 도로 풀리는데, 화면에서 연타하거나 네트워크가 재시도하면 실제로 그렇게 된다.
 *
 * @param completed true면 완료, false면 완료 해제
 */
public record CalendarEventCompleteRequest(

        @NotNull(message = "완료 여부는 필수입니다.")
        Boolean completed
) {
}
