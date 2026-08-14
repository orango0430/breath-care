package org.exaple.breath_care.statistics.dto;

import java.time.LocalDate;

/**
 * 하루치 평균. 차트의 점 하나에 대응한다.
 *
 * <p><b>측정이 없는 날도 빠지지 않고 내려간다.</b> measurementCount가 0이고 값은 전부 null이다.
 * 요일별 차트에서 빈 칸을 그리려면 그 날이 존재한다는 사실 자체가 필요하기 때문이다.
 */
public record DailyMetric(
        LocalDate date,
        Double hr,
        Double hrv,
        Double stressScore,
        int measurementCount
) {
    public static DailyMetric empty(LocalDate date) {
        return new DailyMetric(date, null, null, null, 0);
    }
}
