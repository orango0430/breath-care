package org.exaple.breath_care.calendar;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.dto.CalendarSyncRequest;
import org.exaple.breath_care.calendar.dto.CalendarSyncResponse;
import org.exaple.breath_care.global.response.ApiResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/calendar")
@RequiredArgsConstructor
public class CalendarSyncController {

    private final CalendarSyncService calendarSyncService;

    /**
     * 폰 캘린더 동기화. 앱이 구간을 훑어 그 안의 일정을 통째로 보낸다.
     *
     * <p>여러 번 호출해도 결과가 같다. 앱은 실패하면 그냥 다시 부르면 된다.
     * 회원 전용이다 — 비회원은 서버에 일정을 두지 않으므로 알림도 보낼 수 없다.
     */
    @PostMapping("/sync")
    public ApiResponse<CalendarSyncResponse> sync(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody CalendarSyncRequest request) {

        return ApiResponse.ok(calendarSyncService.sync(userId, request));
    }
}
