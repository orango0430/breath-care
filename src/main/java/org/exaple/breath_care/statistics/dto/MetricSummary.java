package org.exaple.breath_care.statistics.dto;

import java.util.List;

/**
 * 한 지표의 기간 요약. 시안의 "평균 82 / 최고 94 / 최소 68" 부분이다.
 *
 * @param count 이 지표를 실제로 가진 측정 수. HRV나 스트레스 지수는 비어 있을 수 있어
 *              전체 측정 수와 다를 수 있다
 */
public record MetricSummary(Double avg, Double max, Double min, int count) {

    private static final MetricSummary EMPTY = new MetricSummary(null, null, null, 0);

    /** null 값은 제외하고 집계한다. 값이 하나도 없으면 전부 null. */
    public static MetricSummary of(List<Double> values) {
        List<Double> present = values.stream().filter(java.util.Objects::nonNull).toList();
        if (present.isEmpty()) {
            return EMPTY;
        }

        return new MetricSummary(
                present.stream().mapToDouble(Double::doubleValue).average().orElseThrow(),
                present.stream().mapToDouble(Double::doubleValue).max().orElseThrow(),
                present.stream().mapToDouble(Double::doubleValue).min().orElseThrow(),
                present.size());
    }
}
