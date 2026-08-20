package org.exaple.breath_care.measurement.score;

/**
 * 컨디션 지수 산출. 스프링에 의존하지 않는 순수 계산이라 단위 테스트로 상수를 조정할 수 있다.
 *
 * <p>HRV 하나를 0~100으로 옮기는 선형 변환이다. <b>개인 기준선이 필요 없어서 첫 측정부터
 * 값이 나온다.</b> 이전에 쓰던 스트레스 지수({@link StressScoreCalculator})는 최근 20회
 * 심박수와 비교하는 방식이라 측정 5회를 채우기 전에는 계속 null이었다.
 *
 * <p><b>계수는 근거가 확정된 값이 아니다.</b> {@code SDNN 27ms -> 78점}이라는 앵커 하나에
 * {@code SDNN 0 -> 40점}을 붙여 기울기를 뽑은 것이고, 그 27ms는 성인 휴식기 정상값이라고
 * 알려진 범위(단기 기록 기준 30~50ms)보다 오히려 낮다. 게다가 그 범위는 5분 이상
 * 기록에서 나온 것이라 20초짜리 우리 측정에 그대로 갖다 붙일 수 없다. SDNN은 기록이
 * 길수록 커지기 때문이다.
 *
 * <p>그래서 지금 값은 <b>실측 파형으로 갈아 끼울 자리표시</b>다. 확인할 것은 둘이다.
 * <ol>
 *   <li>20초 측정에서 SDNN이 실제로 떨어지는 대역. 지금 상한 96점은 SDNN 40ms에서 걸리는데,
 *       그 위가 전부 같은 점수가 되면 건강한 사람일수록 구별이 안 된다</li>
 *   <li>SDNN과 RMSSD 중 어느 쪽이 사람을 더 잘 가르는지. 둘 다 저장하므로 입력만 바꾸면 된다</li>
 * </ol>
 */
public final class ConditionScoreCalculator {

    /**
     * 로그 척도의 기울기·절편. HRV <b>배수</b>당 점수 증가폭이다. [튜닝 대상]
     *
     * <p>선형이었다가 바꿨다. {@code SDNN × 1.4 + 40}은 <b>40ms에서 상한 96에 닿아서</b>,
     * 그 위는 전부 96점이었다. 실기기로 재면 계속 96만 나왔다 — 20초 측정의 SDNN이
     * 대체로 그 위에 있고, 간격 이상치를 ±30%까지 받아 주므로 흔들림만으로도 쉽게
     * 100ms를 넘기기 때문이다. 모두가 만점이면 지표가 아니다.
     *
     * <p>로그를 쓰는 이유는 HRV의 분포가 그렇게 생겼기 때문이다. 사람 사이 차이가
     * 절대값이 아니라 배수로 벌어져서, 15ms와 30ms의 간격이 100ms와 115ms의 간격보다
     * 훨씬 크게 느껴진다. 앵커는 {@code 15ms→55점}, {@code 120ms→94점} 두 개다.
     *
     * <p>중간값은 이렇게 간다: 30ms 66점, 40ms 73점, 60ms 81점, 100ms 91점.
     * 상한에 닿는 건 170ms 부근이라, 생리학적으로 말이 되는 범위에서는 천장을 치지
     * 않는다. <b>앵커 자체는 여전히 실측으로 확인할 자리표시다.</b>
     */
    private static final double LOG_SLOPE = 18.76;

    private static final double LOG_INTERCEPT = 4.2;

    /** 로그를 취할 수 없는 값의 하한. 이 아래는 전부 최저점으로 본다. */
    private static final double MIN_HRV_MS = 1.0;

    /** 하한. 아무리 나빠도 이 아래로는 안 내려간다. [튜닝 대상] */
    private static final double MIN_SCORE = 50.0;

    /** 상한. [튜닝 대상] */
    private static final double MAX_SCORE = 96.0;

    private ConditionScoreCalculator() {
    }

    /**
     * HRV를 0~100 점수로 옮긴다. <b>높을수록 좋다.</b>
     *
     * @param hrvSdnn SDNN(ms). 품질이 낮아 계산하지 못했으면 null
     * @return 컨디션 지수. 입력이 null이면 null
     */
    public static Double score(Double hrvSdnn) {
        if (hrvSdnn == null) {
            return null;
        }

        double raw = LOG_SLOPE * Math.log(Math.max(MIN_HRV_MS, hrvSdnn)) + LOG_INTERCEPT;
        double clamped = Math.min(MAX_SCORE, Math.max(MIN_SCORE, raw));

        // 소수 첫째 자리로 끊는다. 안 하면 23.4 * 1.4 + 40 이 72.75999999999999로 나가서
        // 앱 화면과 리포트에 그대로 실린다. 신호처리도 같은 자리에서 반올림한다.
        return Math.round(clamped * 10.0) / 10.0;
    }
}
