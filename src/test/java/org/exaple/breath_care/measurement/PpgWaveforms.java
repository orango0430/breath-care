package org.exaple.breath_care.measurement;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

/**
 * 컨트롤러 테스트가 쓰는 합성 PPG 파형.
 *
 * <p>신호처리가 스텁이던 시절에는 아무 값이나 보내도 고정값이 돌아왔지만, 이제는 진짜로
 * 심박수를 뽑아내므로 <b>파형이 사람의 맥박처럼 생겨야 한다.</b> 톱니파를 보내면 엉뚱한
 * 심박수가 나오거나 품질 게이트에 걸린다.
 *
 * <p>{@link Random}에 씨앗을 고정해 두어 같은 인자면 언제나 같은 파형이 나온다.
 * 알고리즘 자체의 검증은 {@code PpgSignalProcessorTest}가 한다. 여기서는 API가
 * 정상 응답을 내는 데 필요한 "그럴듯한 입력"을 만드는 것이 목적이다.
 */
public final class PpgWaveforms {

    /** 손가락을 덮었을 때의 밝기 평균. */
    private static final double DC = 180.0;
    /** 맥동 성분. DC 대비 약 2.8%로 실제 관류 지수 대역이다. */
    private static final double PULSE_AMPLITUDE = 5.0;
    /** 한 박동의 폭(ms). */
    private static final double PULSE_WIDTH_MS = 100.0;

    /** 기본 파형의 목표 심박수. 이 값으로 만든 신호는 72 근처로 복원된다. */
    public static final double DEFAULT_BPM = 72.0;

    private PpgWaveforms() {
    }

    /** 60초·30fps의 기본 파형을 담은 요청 본문. */
    public static String requestBody() {
        return requestBody(60, 30);
    }

    /** 지정한 길이·프레임수의 요청 본문. frameCount를 줄이면 프레임 드랍 상황이 된다. */
    public static String requestBody(int durationSec, int fps) {
        return """
                {"samples":[%s],"fps":%d,"durationSec":%d}
                """.formatted(join(samples(DEFAULT_BPM, durationSec, fps)), fps, durationSec);
    }

    /** 프레임이 모자란 상황. 앞에서 frameCount 개만 보낸다. */
    public static String droppedFrameBody(int durationSec, int fps, int frameCount) {
        double[] full = samples(DEFAULT_BPM, durationSec, fps);
        double[] partial = new double[Math.min(frameCount, full.length)];
        System.arraycopy(full, 0, partial, 0, partial.length);

        return """
                {"samples":[%s],"fps":%d,"durationSec":%d}
                """.formatted(join(partial), fps, durationSec);
    }

    /** 맥동이 전혀 없는 평평한 신호. 손가락을 대지 않은 상황이다. */
    public static String flatBody(int durationSec, int fps) {
        double[] flat = new double[durationSec * fps];
        java.util.Arrays.fill(flat, DC);

        return """
                {"samples":[%s],"fps":%d,"durationSec":%d}
                """.formatted(join(flat), fps, durationSec);
    }

    private static double[] samples(double bpm, int durationSec, int fps) {
        Random random = new Random(1);
        double meanRr = 60_000.0 / bpm;

        List<Double> beats = new ArrayList<>();
        double at = 300.0;
        while (at < durationSec * 1000.0) {
            beats.add(at);
            at += meanRr + random.nextGaussian() * 20.0;
        }

        double[] samples = new double[durationSec * fps];
        for (int i = 0; i < samples.length; i++) {
            double timeMs = i * 1000.0 / fps;
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

    private static String join(double[] values) {
        return IntStream.range(0, values.length)
                .mapToObj(i -> String.format("%.2f", values[i]))
                .collect(Collectors.joining(","));
    }
}
