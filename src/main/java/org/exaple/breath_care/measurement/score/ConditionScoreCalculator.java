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

    /** 기울기. HRV 1ms당 점수 증가폭. [튜닝 대상] */
    private static final double SLOPE = 1.4;

    /** 절편. HRV가 0일 때의 점수. [튜닝 대상] */
    private static final double INTERCEPT = 40.0;

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

        double raw = hrvSdnn * SLOPE + INTERCEPT;
        double clamped = Math.min(MAX_SCORE, Math.max(MIN_SCORE, raw));

        // 소수 첫째 자리로 끊는다. 안 하면 23.4 * 1.4 + 40 이 72.75999999999999로 나가서
        // 앱 화면과 리포트에 그대로 실린다. 신호처리도 같은 자리에서 반올림한다.
        return Math.round(clamped * 10.0) / 10.0;
    }
}
