package org.exaple.breath_care.session.dto;

/**
 * 전후 변화량. 절대 변화와 비율을 모두 준다.
 *
 * <p>스트레스 지수는 <b>줄어드는 것이 좋아진 것</b>이고, HRV는 늘어나는 것이 좋아진 것이다.
 * 부호 해석이 지표마다 달라 화면에서 색을 정할 때 주의해야 한다.
 *
 * <p>어느 한쪽 값이 없으면(품질 미달로 HRV가 비었거나 baseline 전이라 점수가 없을 때)
 * 해당 지표의 변화량은 null이다.
 */
public record MetricChange(
        Double hr, Double hrPercent,
        Double hrv, Double hrvPercent,
        Double stressScore, Double stressScorePercent
) {
    public static MetricChange between(MetricSnapshot before, MetricSnapshot after) {
        return new MetricChange(
                diff(before.hr(), after.hr()), percent(before.hr(), after.hr()),
                diff(before.hrv(), after.hrv()), percent(before.hrv(), after.hrv()),
                diff(before.stressScore(), after.stressScore()), percent(before.stressScore(), after.stressScore()));
    }

    private static Double diff(Double before, Double after) {
        return (before == null || after == null) ? null : after - before;
    }

    private static Double percent(Double before, Double after) {
        if (before == null || after == null || before == 0.0) {
            return null;
        }
        return (after - before) / before * 100.0;
    }
}
