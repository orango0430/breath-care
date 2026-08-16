package org.exaple.breath_care.calendar.dto;

/**
 * 동기화 결과. 앱이 "일정 3개를 새로 가져왔어요"를 보여줄 수 있게 한다.
 *
 * @param created 새로 저장된 일정 수
 * @param updated 제목·시각이 바뀌어 갱신된 수
 * @param deleted 폰에서 지워져 함께 지운 수
 */
public record CalendarSyncResponse(
        int created,
        int updated,
        int deleted
) {
}
