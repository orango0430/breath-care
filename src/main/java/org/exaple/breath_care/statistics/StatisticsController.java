package org.exaple.breath_care.statistics;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.statistics.dto.DailyMetric;
import org.exaple.breath_care.statistics.dto.StatisticsSummaryResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

/**
 * 측정 통계. from·to를 생략하면 오늘 포함 최근 7일이다.
 * 날짜 경계는 한국 시간 기준으로 자른다.
 */
@RestController
@RequestMapping("/api/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    /** 기간 요약. 시안의 "평균 82 / 최고 94 / 최소 68". */
    @GetMapping("/summary")
    public ApiResponse<StatisticsSummaryResponse> summary(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        return ApiResponse.ok(statisticsService.summary(userId, from, to));
    }

    /** 일별 평균. 차트용이라 측정이 없는 날도 빈 값으로 함께 내려간다. */
    @GetMapping("/daily")
    public ApiResponse<List<DailyMetric>> daily(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        return ApiResponse.ok(statisticsService.daily(userId, from, to));
    }
}
