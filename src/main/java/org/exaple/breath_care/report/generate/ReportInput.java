package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.statistics.dto.DailyMetric;
import org.exaple.breath_care.statistics.dto.MetricSummary;

import java.time.LocalDate;
import java.util.List;

/**
 * 리포트 생성에 넣는 재료.
 *
 * <p><b>원시 측정 기록은 넣지 않는다.</b> 집계값만으로도 리포트에 쓸 내용은 다 나오는데,
 * 측정을 한 건씩 나열하면 입력 토큰만 몇 배로 늘어난다. 주 20건이면 그 차이가 그대로 비용이다.
 */
public record ReportInput(
        LocalDate from,
        LocalDate to,
        int measurementCount,
        MetricSummary hr,
        MetricSummary hrv,
        MetricSummary stressScore,
        List<DailyMetric> daily
) {
}
