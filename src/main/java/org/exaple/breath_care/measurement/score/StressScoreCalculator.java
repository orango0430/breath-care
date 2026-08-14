package org.exaple.breath_care.measurement.score;

import java.util.List;

/**
 * 스트레스 지수 산출. 스프링에 의존하지 않는 순수 계산이라 단위 테스트로 상수를 조정할 수 있다.
 *
 * <p><b>절대적인 긴장도가 아니라 "내 평소보다 얼마나 높은가"</b>를 점수화한다.
 * 안정시 심박수는 사람마다 55~85로 크게 달라, 일반 기준값으로는 의미 있는 값이 나오지 않는다.
 *
 * <p>계수는 실측 데이터로 조정할 대상이다. 근거가 있어 고른 값이 아니라 출발점일 뿐이다.
 */
public final class StressScoreCalculator {

    /** 기준선 계산에 쓰는 최근 측정 개수. */
    public static final int BASELINE_WINDOW = 20;

    /** 표준편차 하한. 측정값이 우연히 똑같으면 0으로 나누게 되고, 작은 편차도 과대 해석된다. */
    private static final double MIN_SD = 3.0;

    /** 로지스틱 기울기. 클수록 점수가 급격히 변한다. [튜닝 대상] */
    private static final double STEEPNESS = 1.2;

    /** 점수 50이 되는 지점(표준편차 배수). [튜닝 대상] */
    private static final double MIDPOINT_Z = 1.0;

    private StressScoreCalculator() {
    }

    /** 최근 심박수들로 기준선을 만든다. 표본이 모자라면 계산하지 않는다. */
    public static Baseline baselineOf(List<Double> recentHrs) {
        int count = recentHrs.size();
        if (count < Baseline.MIN_SAMPLES) {
            return Baseline.notReady(count);
        }

        double mean = recentHrs.stream().mapToDouble(Double::doubleValue).average().orElseThrow();
        double variance = recentHrs.stream()
                .mapToDouble(hr -> (hr - mean) * (hr - mean))
                .sum() / (count - 1);          // 표본 분산

        return new Baseline(mean, Math.sqrt(variance), count);
    }

    /**
     * 기준선 대비 편차를 0~100으로 매핑한다. 기준선이 없으면 null.
     *
     * <pre>
     * 평소와 같음(z=0) → 23점
     * +1 표준편차      → 50점
     * +2 표준편차      → 77점
     * +3 표준편차      → 92점
     * </pre>
     */
    public static Double score(double hr, Baseline baseline) {
        if (!baseline.isReady()) {
            return null;
        }

        double sd = Math.max(baseline.sd(), MIN_SD);
        double z = (hr - baseline.hr()) / sd;

        return 100.0 / (1.0 + Math.exp(-STEEPNESS * (z - MIDPOINT_Z)));
    }
}
