package org.exaple.breath_care.measurement.score;

/**
 * 개인 기준선. 최근 측정들의 평균 심박수와 표준편차다.
 *
 * @param hr          평균 심박수
 * @param sd          표준편차
 * @param sampleCount 계산에 쓰인 측정 수
 */
public record Baseline(double hr, double sd, int sampleCount) {

    /** 표본이 이만큼 쌓여야 점수를 낸다. 그 전에는 일반 기준값을 쓰느니 아무것도 안 보여주는 게 낫다. */
    public static final int MIN_SAMPLES = 5;

    public static Baseline notReady(int sampleCount) {
        return new Baseline(0, 0, sampleCount);
    }

    public boolean isReady() {
        return sampleCount >= MIN_SAMPLES;
    }

    /** 기준선 완성까지 남은 측정 횟수. */
    public int remainingSamples() {
        return Math.max(0, MIN_SAMPLES - sampleCount);
    }
}
