package org.exaple.breath_care.measurement.signal;

/**
 * 원시 PPG 파형에서 심박수·HRV·품질을 산출한다.
 *
 * <p>스프링에 의존하지 않는 순수 계산으로 유지한다. DB나 서버 없이 단위 테스트로
 * 필터 컷오프·피크 임계값 같은 상수를 실측 데이터에 맞춰 조정할 수 있어야 하기 때문이다.
 */
public interface SignalProcessor {

    /**
     * @param samples 빨강 채널 평균값 배열
     * @param fps     초당 샘플 수
     */
    SignalResult process(double[] samples, int fps);
}
