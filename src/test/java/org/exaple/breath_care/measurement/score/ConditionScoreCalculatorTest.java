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
    @DisplayName("설계 앵커: SDNN 27ms가 78점 근처로 간다")
    void anchorPoint() {
        // 27 × 1.4 + 40 = 77.8. 계수를 바꾸면 이 앵커도 같이 옮겨야 한다.
        assertThat(ConditionScoreCalculator.score(27.0)).isCloseTo(77.8, org.assertj.core.data.Offset.offset(0.01));
    }

    /**
     * 배포된 서버에서 {@code 72.75999999999999}가 응답에 그대로 실려 나온 적이 있다.
     * 부동소수점 찌꺼기가 앱 화면과 AI 리포트까지 따라간다.
     */
    @Test
    @DisplayName("소수 첫째 자리까지만 낸다 — 부동소수점 찌꺼기를 흘리지 않는다")
    void roundsToOneDecimal() {
        // 23.4 * 1.4 + 40 은 double로 계산하면 72.75999999999999가 된다
        assertThat(ConditionScoreCalculator.score(23.4)).isEqualTo(72.8);
        assertThat(ConditionScoreCalculator.score(19.6)).isEqualTo(67.4);
    }

    @Test
    @DisplayName("어떤 입력에도 50~96을 벗어나지 않는다")
    void alwaysWithinRange() {
        assertThat(ConditionScoreCalculator.score(0.0)).isBetween(50.0, 96.0);
        assertThat(ConditionScoreCalculator.score(-5.0)).isBetween(50.0, 96.0);
        assertThat(ConditionScoreCalculator.score(1000.0)).isBetween(50.0, 96.0);
    }

    /**
     * 지금 공식의 가장 큰 약점을 못으로 박아 둔다.
     *
     * <p>SDNN 40ms 위는 전부 96점이다. 그런데 성인 휴식기 정상값이라고 알려진 범위가
     * 단기 기록 기준 30~50ms라, <b>건강한 사람일수록 서로 구별이 안 된다.</b>
     * 실측 파형을 받아 20초 측정에서 SDNN이 실제로 어느 대역에 떨어지는지 보고
     * 상한을 올리거나 기울기를 낮춰야 한다. 그때 이 테스트를 고치는 것이 곧 그 작업이다.
     */
    @Test
    @DisplayName("[알려진 한계] SDNN 40 이상은 전부 같은 점수로 뭉개진다")
    void saturatesAboveFortyMs() {
        assertThat(ConditionScoreCalculator.score(40.0)).isEqualTo(96.0);
        assertThat(ConditionScoreCalculator.score(55.0)).isEqualTo(96.0);
        assertThat(ConditionScoreCalculator.score(65.0)).isEqualTo(96.0);
    }
}
