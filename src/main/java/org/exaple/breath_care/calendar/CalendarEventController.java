package org.exaple.breath_care.calendar;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.dto.CalendarEventRequest;
import org.exaple.breath_care.calendar.dto.CalendarEventResponse;
import org.exaple.breath_care.global.response.ApiResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/calendar/events")
@RequiredArgsConstructor
public class CalendarEventController {

    private final CalendarEventService calendarEventService;

    @PostMapping
    public ResponseEntity<ApiResponse<CalendarEventResponse>> create(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody CalendarEventRequest request) {

        CalendarEventResponse created = calendarEventService.create(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    /**
     * 기간 조회. from·to는 생략 가능하며, 둘 다 없으면 내 일정 전체를 시각순으로 준다.
     * to는 포함하지 않는다(from &lt;= startAt &lt; to). 달력 화면이 월 경계를 그대로 넘기면 된다.
     */
    @GetMapping
    public ApiResponse<List<CalendarEventResponse>> findInRange(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        return ApiResponse.ok(calendarEventService.findInRange(userId, from, to));
    }

    @PutMapping("/{eventId}")
    public ApiResponse<CalendarEventResponse> update(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long eventId,
            @Valid @RequestBody CalendarEventRequest request) {

        return ApiResponse.ok(calendarEventService.update(userId, eventId, request));
    }

    @DeleteMapping("/{eventId}")
    public ApiResponse<Void> delete(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long eventId) {

        calendarEventService.delete(userId, eventId);
        return ApiResponse.ok(null);
    }
}
