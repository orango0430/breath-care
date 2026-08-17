package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 실제 신호처리가 붙기 전까지 쓰는 임시 구현. 계약을 먼저 확정해 프론트가 연동을 시작할 수 있게 한다.
 *
 * <p><b>고정값을 돌려준다.</b> 다만 샘플이 명백히 모자란 경우는 POOR로 걸러서,
 * 프론트가 재측정 요구 흐름을 미리 다뤄볼 수 있게 했다.
 * 실제 구현이 들어오면 이 클래스는 삭제한다.
 */
@Component
public class StubSignalProcessor implements SignalProcessor {

    private static final Logger log = LoggerFactory.getLogger(StubSignalProcessor.class);

    /** 이 시간보다 짧으면 심박수조차 신뢰할 수 없다. */
    private static final int MIN_DURATION_SEC = 20;

    private static final double STUB_HR = 72.0;
    private static final double STUB_HRV = 35.0;

    /**
     * 경고는 기동할 때 한 번만 남긴다.
     *
     * <p>요청마다 WARN을 찍던 걸 옮긴 것이다. 비회원 측정은 인증 없이 열려 있어서
     * 행사처럼 사람이 몰리면 초당 수천 줄이 쌓인다. 부하 테스트에서 실제로 확인했다.
     * 경고 자체는 남겨야 한다 — 스텁인 걸 모르고 배포하는 게 더 위험하다.
     */
    public StubSignalProcessor() {
        log.warn("신호처리가 아직 스텁입니다. 심박수·HRV는 고정값으로 나갑니다.");
    }

    @Override
    public SignalResult process(double[] samples, int fps) {
        log.debug("스텁 신호처리 (samples={}, fps={})", samples.length, fps);

        if (samples.length < (long) fps * MIN_DURATION_SEC) {
            return SignalResult.poor();
        }

        return new SignalResult(STUB_HR, STUB_HRV, MeasurementQuality.GOOD);
    }
}
