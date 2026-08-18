package org.exaple.breath_care.breathing;

/**
 * 호흡 한 주기 안의 한 걸음.
 *
 * <p>4-4-4-4처럼 "들숨·멈춤·날숨·멈춤" 네 칸으로 고정하지 않고 순서 있는 목록으로 둔 이유는
 * 생리학적 한숨 때문이다. 이 호흡은 <b>들숨이 두 번 연달아</b> 나오므로 네 칸에 들어가지 않는다.
 *
 * @param seconds 이 걸음의 길이(초). 공진 호흡의 5.5초 때문에 정수가 아니다
 */
public record BreathStep(BreathPhase phase, double seconds) {

    static BreathStep inhale(double seconds) {
        return new BreathStep(BreathPhase.INHALE, seconds);
    }

    static BreathStep hold(double seconds) {
        return new BreathStep(BreathPhase.HOLD, seconds);
    }

    static BreathStep exhale(double seconds) {
        return new BreathStep(BreathPhase.EXHALE, seconds);
    }
}
