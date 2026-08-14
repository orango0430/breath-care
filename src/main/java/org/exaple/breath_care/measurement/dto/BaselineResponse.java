package org.exaple.breath_care.measurement.dto;

import org.exaple.breath_care.measurement.score.Baseline;

/**
 * 개인 기준선 상태. 앱이 "기준을 만드는 중이에요 (N회 더)" 화면을 그리는 데 쓴다.
 *
 * @param ready             기준선이 완성됐는지. false면 스트레스 지수가 계속 null로 나온다
 * @param sampleCount       현재까지 쌓인 측정 수
 * @param remainingSamples  완성까지 남은 횟수
 * @param baselineHr        평균 심박수. 준비 전에는 null
 */
public record BaselineResponse(
        boolean ready,
        int sampleCount,
        int remainingSamples,
        Double baselineHr
) {
    public static BaselineResponse from(Baseline baseline) {
        return new BaselineResponse(
                baseline.isReady(),
                baseline.sampleCount(),
                baseline.remainingSamples(),
                baseline.isReady() ? baseline.hr() : null);
    }
}
