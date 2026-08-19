package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * 합성 신호로 알고리즘을 검증한다.
 *
 * <p><b>이 테스트가 확인하는 것과 못 하는 것을 구분해야 한다.</b> 정답을 아는 파형을 만들어
 * 넣으므로 "심박수를 제대로 복원하는가", "보간이 실제로 효과가 있는가" 같은 <b>알고리즘의
 * 정확성</b>은 확인된다. 반면 임계값(관류 하한, 피크 임계 배수, 이상치 허용폭)이 실제 카메라
 * 신호에 맞는지는 <b>확인되지 않는다.</b> 합성 신호는 실기기보다 훨씬 깨끗하기 때문이다.
 * 그건 실기기 파형을 받아야 안다.
 */
class PpgSignalProcessorTest {

    private static final int FPS = 30;

    private final PpgSignalProcessor processor = new PpgSignalProcessor();

    // ------------------------------------------------------------------
    // 합성 신호 생성기
    // ------------------------------------------------------------------

    /** 손가락을 덮었을 때의 밝기 평균. 실제 값과 자릿수만 맞추면 된다. */
    private static final double DC = 180.0;

    /** 맥동 성분의 크기. DC 대비 약 2.8%로, 실제 관류 지수(0.5~3%)와 같은 대역이다. */
    private static final double PULSE_AMPLITUDE = 5.0;

    /** 한 박동의 폭(ms). 실제 PPG 파형의 수축기 봉우리와 비슷하게 잡았다. */
    private static final double PULSE_WIDTH_MS = 100.0;

    /**
     * 정답을 아는 PPG 파형을 만든다.
     *
     * @param bpm     목표 심박수
     * @param seconds 측정 길이(초)
     * @param sdnnMs  박동 간격에 줄 흔들림의 표준편차. 0이면 완전히 규칙적인 신호다
     */
    private double[] synthesize(double bpm, int seconds, double sdnnMs, long seed) {
        Random random = new Random(seed);
        double meanRr = 60_000.0 / bpm;

        List<Double> beats = new ArrayList<>();
        double at = 300.0;
        while (at < seconds * 1000.0) {
            beats.add(at);
            at += meanRr + random.nextGaussian() * sdnnMs;
        }

        double[] samples = new double[seconds * FPS];
        for (int i = 0; i < samples.length; i++) {
            double timeMs = i * 1000.0 / FPS;
            double value = DC;
            for (double beat : beats) {
                double dt = (timeMs - beat) / PULSE_WIDTH_MS;
                if (Math.abs(dt) < 5) {
                    value += PULSE_AMPLITUDE * Math.exp(-dt * dt);
                }
            }
            samples[i] = value;
        }
        return samples;
    }

    // ------------------------------------------------------------------
    // 심박수 복원
    // ------------------------------------------------------------------

    @Test
    @DisplayName("아는 심박수를 복원한다 — 72 bpm")
    void recoversHeartRate() {
        SignalResult result = processor.process(synthesize(72, 30, 20, 1), FPS);

        assertThat(result.quality()).isEqualTo(MeasurementQuality.GOOD);
        assertThat(result.hr()).isCloseTo(72.0, within(2.0));
    }

    @Test
    @DisplayName("느린 심박과 빠른 심박 모두 복원한다")
    void recoversAcrossRange() {
        assertThat(processor.process(synthesize(52, 30, 15, 2), FPS).hr()).isCloseTo(52.0, within(2.0));
        assertThat(processor.process(synthesize(110, 30, 15, 3), FPS).hr()).isCloseTo(110.0, within(2.0));
    }

    // ------------------------------------------------------------------
    // HRV
    // ------------------------------------------------------------------

    @Test
    @DisplayName("넣어 준 흔들림 크기를 SDNN으로 되찾는다")
    void recoversSdnn() {
        // 흔들림 40ms로 만든 신호. 양자화 잡음이 남아 있어 정확히 40은 아니지만 같은 대역이어야 한다.
        SignalResult result = processor.process(synthesize(72, 60, 40, 4), FPS);

        assertThat(result.hrvSdnn()).isCloseTo(40.0, within(12.0));
    }

    @Test
    @DisplayName("흔들림이 클수록 SDNN도 커진다")
    void sdnnFollowsVariability() {
        Double steady = processor.process(synthesize(72, 60, 10, 5), FPS).hrvSdnn();
        Double variable = processor.process(synthesize(72, 60, 50, 5), FPS).hrvSdnn();

        assertThat(steady).isLessThan(variable);
    }

    /**
     * 포물선 보간의 존재 이유를 못으로 박는다.
     *
     * <p>73bpm의 박동 간격은 821.9ms이고, 30fps에서 24.657 샘플이다. <b>정수가 아니다.</b>
     * 피크를 가장 가까운 프레임으로만 잡으면 간격이 24와 25 샘플 사이를 오가며
     * 실제로는 없는 흔들림이 약 13.5ms 생긴다. 보간이 그걸 없앤다.
     *
     * <p>72bpm(정확히 25샘플)으로 시험하면 보간이 없어도 통과하므로 의미가 없다.
     * 이 테스트의 73이라는 숫자는 그래서 고른 것이다.
     */
    @Test
    @DisplayName("완전히 규칙적인 신호의 SDNN은 양자화 바닥(13.5ms)보다 훨씬 작다")
    void interpolationBeatsFrameQuantization() {
        SignalResult result = processor.process(synthesize(73, 60, 0, 6), FPS);

        assertThat(result.hrvSdnn())
                .as("보간이 빠지면 13.5ms 근처가 나온다")
                .isLessThan(5.0);
    }

    @Test
    @DisplayName("RMSSD와 SDNN을 함께 낸다")
    void reportsBothHrvMetrics() {
        SignalResult result = processor.process(synthesize(72, 60, 30, 7), FPS);

        assertThat(result.hrv()).as("RMSSD").isNotNull().isPositive();
        assertThat(result.hrvSdnn()).as("SDNN").isNotNull().isPositive();
    }

    // ------------------------------------------------------------------
    // 품질 게이트
    // ------------------------------------------------------------------

    @Test
    @DisplayName("맥동이 없는 평평한 신호는 POOR — 손가락이 안 닿은 경우다")
    void flatSignalIsPoor() {
        double[] flat = new double[30 * FPS];
        java.util.Arrays.fill(flat, DC);

        assertThat(processor.process(flat, FPS).quality()).isEqualTo(MeasurementQuality.POOR);
        assertThat(processor.process(flat, FPS).hr()).isNull();
    }

    @Test
    @DisplayName("잡음뿐인 신호는 POOR")
    void noiseIsPoor() {
        Random random = new Random(8);
        double[] noise = new double[30 * FPS];
        for (int i = 0; i < noise.length; i++) {
            noise[i] = DC + random.nextGaussian() * 3;
        }

        assertThat(processor.process(noise, FPS).quality()).isEqualTo(MeasurementQuality.POOR);
    }

    @Test
    @DisplayName("20초보다 짧으면 POOR — HRV를 낼 수 없다")
    void tooShortIsPoor() {
        assertThat(processor.process(synthesize(72, 15, 20, 9), FPS).quality())
                .isEqualTo(MeasurementQuality.POOR);
    }

    @Test
    @DisplayName("비어 있거나 null이면 POOR")
    void emptyIsPoor() {
        assertThat(processor.process(null, FPS).quality()).isEqualTo(MeasurementQuality.POOR);
        assertThat(processor.process(new double[0], FPS).quality()).isEqualTo(MeasurementQuality.POOR);
    }

    @Test
    @DisplayName("중간에 손가락이 흔들리면 품질이 내려간다")
    void motionLowersQuality() {
        double[] samples = synthesize(72, 40, 15, 10);
        // 10초부터 4초간 손가락이 밀린 상황. 맥동을 덮어 버리는 큰 흔들림을 씌운다.
        Random random = new Random(11);
        for (int i = 10 * FPS; i < 14 * FPS; i++) {
            samples[i] += random.nextGaussian() * 25;
        }

        assertThat(processor.process(samples, FPS).quality())
                .isNotEqualTo(MeasurementQuality.GOOD);
    }

    // ------------------------------------------------------------------
    // 기타
    // ------------------------------------------------------------------

    @Test
    @DisplayName("기저선이 크게 흘러도 심박수는 흔들리지 않는다")
    void toleratesBaselineDrift() {
        double[] samples = synthesize(72, 40, 20, 12);
        // 손가락 압력이 서서히 변해 밝기가 통째로 40만큼 오르는 상황.
        for (int i = 0; i < samples.length; i++) {
            samples[i] += 40.0 * i / samples.length;
        }

        SignalResult result = processor.process(samples, FPS);

        assertThat(result.quality()).isEqualTo(MeasurementQuality.GOOD);
        assertThat(result.hr()).isCloseTo(72.0, within(2.0));
    }

    @Test
    @DisplayName("60fps로 보내도 같은 심박수가 나온다")
    void independentOfFrameRate() {
        // 60fps 파형은 별도로 만든다. 생성기가 FPS 상수를 쓰므로 여기서만 직접 만든다.
        int fps = 60;
        int seconds = 30;
        double meanRr = 60_000.0 / 68;
        double[] samples = new double[seconds * fps];
        for (int i = 0; i < samples.length; i++) {
            double timeMs = i * 1000.0 / fps;
            double value = DC;
            for (double beat = 300.0; beat < seconds * 1000.0; beat += meanRr) {
                double dt = (timeMs - beat) / PULSE_WIDTH_MS;
                if (Math.abs(dt) < 5) {
                    value += PULSE_AMPLITUDE * Math.exp(-dt * dt);
                }
            }
            samples[i] = value;
        }

        assertThat(processor.process(samples, fps).hr()).isCloseTo(68.0, within(2.0));
    }
}
