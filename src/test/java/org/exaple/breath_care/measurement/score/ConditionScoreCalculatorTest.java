package org.exaple.breath_care.measurement.score;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 컨디션 지수. 상수는 실측 파형으로 갈아 끼울 자리표시라, 여기서는 <b>값 자체보다
 * 성질</b>을 고정한다. 계수를 조정할 때 이 테스트가 깨지면 성질이 무너진 것이다.
 */
class ConditionScoreCalculatorTest {

    @Test
    @DisplayName("HRV가 없으면 점수도 없다")
    void nullWithoutHrv() {
        assertThat(ConditionScoreCalculator.score(null)).isNull();
    }

    @Test
    @DisplayName("이력이 없어도 값 하나로 바로 계산된다 — 기준선이 필요 없다")
    void needsNoBaseline() {
        // 스트레스 지수(StressScoreCalculator)는 최근 20회 심박수를 받아야 했다.
        // 컨디션 지수는 인자가 HRV 하나뿐이다. 이게 지표를 바꾼 이유다.
        assertThat(ConditionScoreCalculator.score(32.0)).isNotNull();
    }

    @Test
    @DisplayName("HRV가 높을수록 점수가 높다")
    void higherHrvScoresHigher() {
        Double low = ConditionScoreCalculator.score(15.0);
        Double mid = ConditionScoreCalculator.score(25.0);
        Double high = ConditionScoreCalculator.score(35.0);

        assertThat(low).isLessThan(mid);
        assertThat(mid).isLessThan(high);
    }

    @Test
    @DisplayName("설계 앵커: SDNN 15ms가 55점, 120ms가 94점")
    void anchorPoints() {
        // 로그 매핑을 고정하는 두 점이다. 계수를 바꾸면 여기부터 깨진다.
        assertThat(ConditionScoreCalculator.score(15.0))
                .isCloseTo(55.0, org.assertj.core.data.Offset.offset(0.2));
        assertThat(ConditionScoreCalculator.score(120.0))
                .isCloseTo(94.0, org.assertj.core.data.Offset.offset(0.2));
    }

    @Test
    @DisplayName("실기기에서 흔한 SDNN 대역이 만점에 붙지 않는다")
    void doesNotSaturateInTheRealWorldBand() {
        // 선형이던 시절 40ms부터 전부 96점이었다. 실기기로 재면 계속 96만 나와서
        // 지표 구실을 못 했다. 이 대역이 갈라지는지가 이 변경의 핵심이다.
        Double at40 = ConditionScoreCalculator.score(40.0);
        Double at60 = ConditionScoreCalculator.score(60.0);
        Double at100 = ConditionScoreCalculator.score(100.0);

        assertThat(at40).isLessThan(90.0);
        assertThat(at40).isLessThan(at60);
        assertThat(at60).isLessThan(at100);
        assertThat(at100).isLessThan(96.0);
    }

    /**
     * 배포된 서버에서 {@code 72.75999999999999}가 응답에 그대로 실려 나온 적이 있다.
     * 부동소수점 찌꺼기가 앱 화면과 AI 리포트까지 따라간다.
     */
    @Test
    @DisplayName("소수 첫째 자리까지만 낸다 — 부동소수점 찌꺼기를 흘리지 않는다")
    void roundsToOneDecimal() {
        // 23.4 * 1.4 + 40 은 double로 계산하면 72.75999999999999가 된다
        assertThat(ConditionScoreCalculator.score(23.4)).isEqualTo(63.3);
        assertThat(ConditionScoreCalculator.score(19.6)).isEqualTo(60.0);
    }

    @Test
    @DisplayName("어떤 입력에도 50~96을 벗어나지 않는다")
    void alwaysWithinRange() {
        assertThat(ConditionScoreCalculator.score(0.0)).isBetween(50.0, 96.0);
        assertThat(ConditionScoreCalculator.score(-5.0)).isBetween(50.0, 96.0);
        assertThat(ConditionScoreCalculator.score(1000.0)).isBetween(50.0, 96.0);
    }

    /**
     * 예전 공식의 가장 큰 약점을 못으로 박아 뒀던 자리다.
     *
     * <p>{@code SDNN × 1.4 + 40} 시절에는 40ms 위가 전부 96점이었다. 실기기로 재 보니
     * 20초 측정의 SDNN은 대체로 그 위에 있어서, <b>몇 번을 재도 96점만 나왔다.</b>
     * 로그 매핑으로 바꾼 뒤 이 테스트는 "뭉개지는가"가 아니라 "갈라지는가"를 본다.
     */
    @Test
    @DisplayName("SDNN 40~65 구간이 서로 다른 점수로 갈린다")
    void separatesTheBandThatUsedToSaturate() {
        Double at40 = ConditionScoreCalculator.score(40.0);
        Double at55 = ConditionScoreCalculator.score(55.0);
        Double at65 = ConditionScoreCalculator.score(65.0);

        assertThat(at40).isLessThan(at55);
        assertThat(at55).isLessThan(at65);
        assertThat(at65).isLessThan(96.0);
    }
}
