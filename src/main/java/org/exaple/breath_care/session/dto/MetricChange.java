package org.exaple.breath_care.session.dto;

/**
 * 전후 변화량. 절대 변화와 비율을 모두 준다.
 *
 * <p><b>지표마다 좋아지는 방향이 다르다.</b> 심박수는 줄어드는 것이, HRV와 컨디션 지수는
 * 늘어나는 것이 좋아진 것이다. 화면에서 증감 색을 정할 때 주의해야 한다.
 *
 * <p>V14 전에는 컨디션 지수 자리에 스트레스 지수가 있었고 방향이 <b>반대</b>였다(줄어야 개선).
 * 전후 비교 화면이 그때 부호 처리를 그대로 갖고 있으면, 좋아진 것을 나빠진 것으로 표시한다.
 *
 * <p>어느 한쪽 값이 없으면(품질 미달로 HRV가 비어 컨디션 지수도 없을 때)
 * 해당 지표의 변화량은 null이다.
 */
public record MetricChange(
        Double hr, Double hrPercent,
        Double hrv, Double hrvPercent,
        Double conditionScore, Double conditionScorePercent
) {
    public static MetricChange between(MetricSnapshot before, MetricSnapshot after) {
        return new MetricChange(
                diff(before.hr(), after.hr()), percent(before.hr(), after.hr()),
                diff(before.hrv(), after.hrv()), percent(before.hrv(), after.hrv()),
                diff(before.conditionScore(), after.conditionScore()),
                percent(before.conditionScore(), after.conditionScore()));
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
