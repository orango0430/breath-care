package org.exaple.breath_care.statistics.dto;

import java.time.LocalDate;

/**
 * 기간 요약 통계.
 *
 * <p>값은 반올림하지 않은 원본이다. 화면에 표시할 때만 심박수·스트레스 지수를 5단위로 끊는다.
 *
 * @param from             집계 시작일 (한국 시간 기준)
 * @param to               집계 종료일 (포함)
 * @param measurementCount 기간 내 전체 측정 수
 */
public record StatisticsSummaryResponse(
        LocalDate from,
        LocalDate to,
        int measurementCount,
        MetricSummary hr,
        MetricSummary hrv,
        MetricSummary stressScore
) {
}
