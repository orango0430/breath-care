package org.exaple.breath_care.measurement.score;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/** 스프링 없이 도는 순수 계산 테스트. 상수를 바꾸면 여기서 바로 영향이 보인다. */
class StressScoreCalculatorTest {

    private static List<Double> repeat(double hr, int times) {
        return IntStream.range(0, times).mapToObj(i -> hr).toList();
    }

    @Test
    @DisplayName("표본이 5개 미만이면 기준선을 만들지 않는다")
    void baselineNeedsEnoughSamples() {
        Baseline baseline = StressScoreCalculator.baselineOf(repeat(70.0, 4));

        assertThat(baseline.isReady()).isFalse();
        assertThat(baseline.sampleCount()).isEqualTo(4);
        assertThat(baseline.remainingSamples()).isEqualTo(1);
    }

    @Test
    @DisplayName("표본이 5개 이상이면 평균과 표준편차를 낸다")
    void baselineFromSamples() {
        Baseline baseline = StressScoreCalculator.baselineOf(List.of(68.0, 70.0, 72.0, 74.0, 76.0));

        assertThat(baseline.isReady()).isTrue();
        assertThat(baseline.hr()).isEqualTo(72.0);
        assertThat(baseline.sd()).isCloseTo(3.162, org.assertj.core.data.Offset.offset(0.01));
        assertThat(baseline.remainingSamples()).isZero();
    }

    @Test
    @DisplayName("기준선이 없으면 점수를 내지 않는다")
    void noScoreWithoutBaseline() {
        Baseline notReady = StressScoreCalculator.baselineOf(repeat(70.0, 3));

        assertThat(StressScoreCalculator.score(90.0, notReady)).isNull();
    }

    @Test
    @DisplayName("평소와 같으면 낮은 점수, 평소보다 높으면 높은 점수가 나온다")
    void scoreRisesWithDeviation() {
        // 평균 70, 표준편차 하한 3.0이 적용되는 표본
        Baseline baseline = StressScoreCalculator.baselineOf(repeat(70.0, 10));

        Double atBaseline = StressScoreCalculator.score(70.0, baseline);   // z=0
        Double oneSd = StressScoreCalculator.score(73.0, baseline);        // z=1
        Double twoSd = StressScoreCalculator.score(76.0, baseline);        // z=2
        Double threeSd = StressScoreCalculator.score(79.0, baseline);      // z=3

        assertThat(atBaseline).isCloseTo(23.1, org.assertj.core.data.Offset.offset(0.5));
        assertThat(oneSd).isCloseTo(50.0, org.assertj.core.data.Offset.offset(0.5));
        assertThat(twoSd).isCloseTo(76.9, org.assertj.core.data.Offset.offset(0.5));
        assertThat(threeSd).isCloseTo(91.7, org.assertj.core.data.Offset.offset(0.5));
    }

    @Test
    @DisplayName("평소보다 낮으면 점수가 더 내려간다")
    void lowerThanBaselineScoresLower() {
        Baseline baseline = StressScoreCalculator.baselineOf(repeat(70.0, 10));

        Double calm = StressScoreCalculator.score(64.0, baseline);
        Double normal = StressScoreCalculator.score(70.0, baseline);

        assertThat(calm).isLessThan(normal);
    }

    @Test
    @DisplayName("점수는 항상 0~100 안에 있다")
    void scoreStaysInRange() {
        Baseline baseline = StressScoreCalculator.baselineOf(repeat(70.0, 10));

        assertThat(StressScoreCalculator.score(30.0, baseline)).isBetween(0.0, 100.0);
        assertThat(StressScoreCalculator.score(200.0, baseline)).isBetween(0.0, 100.0);
    }

    @Test
    @DisplayName("측정값이 모두 같아도 0으로 나누지 않는다")
    void handlesZeroDeviation() {
        Baseline baseline = StressScoreCalculator.baselineOf(repeat(70.0, 10));

        assertThat(baseline.sd()).isZero();
        // 표준편차 하한(3.0)이 적용돼 정상 범위의 점수가 나온다
        assertThat(StressScoreCalculator.score(70.0, baseline)).isBetween(0.0, 100.0);
    }
}
