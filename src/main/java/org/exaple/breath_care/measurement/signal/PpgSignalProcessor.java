package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * 카메라 PPG 파형에서 심박수·HRV·품질을 산출한다.
 *
 * <p>처리 순서는 이렇다.
 * <ol>
 *   <li><b>대역통과</b> — 짧은 이동평균(잡음 제거)에서 긴 이동평균(기저선)을 뺀다.
 *       손가락 압력이 변하거나 조도가 바뀌면 신호가 통째로 오르내리는데, 그 성분을 걷어낸다</li>
 *   <li><b>관류 확인</b> — 맥동 성분이 거의 없으면 손가락이 안 닿은 것이다. 여기서 POOR로 끊는다</li>
 *   <li><b>피크 검출</b> — 적응 임계값 + 불응기. 임계값을 고정하면 기기·조도마다 달라진다</li>
 *   <li><b>포물선 보간</b> — 아래 설명 참고. 이게 없으면 HRV의 상당 부분이 양자화 잡음이다</li>
 *   <li><b>RR 이상치 제거</b> — 손가락이 움직이면 간격이 튄다. 중앙값에서 많이 벗어난 것을 버린다</li>
 *   <li><b>지표 산출</b> — HR(평균), SDNN(표준편차), RMSSD(인접 차이)</li>
 * </ol>
 *
 * <p><b>포물선 보간을 넣은 이유.</b> 30fps면 프레임 간격이 33ms다. 피크 시각을 가장 가까운
 * 프레임으로 잡으면 각 시각에 표준편차 33/√12 ≈ 9.5ms의 양자화 오차가 붙고, RR은 두 시각의
 * 차이라 √2배인 <b>약 13.5ms</b>가 된다. 실제 SDNN이 27ms여도 측정값은
 * √(27² + 13.5²) ≈ 30ms로 부풀고, 10ms면 17ms가 나온다. 즉 보간이 없으면 13.5ms 아래는
 * 아예 측정할 수 없다. 피크 좌우 세 점에 포물선을 맞춰 꼭짓점을 찾으면 프레임 사이 위치를
 * 추정할 수 있어 이 바닥을 크게 낮춘다.
 *
 * <p><b>상수는 전부 실측으로 조정할 대상이다.</b> 합성 신호로는 알고리즘이 맞는지만 확인할 수
 * 있고, 임계값이 실제 카메라 신호에 맞는지는 실기기 파형을 받아야 안다.
 */
@Component
public class PpgSignalProcessor implements SignalProcessor {

    /** 이 시간보다 짧으면 HRV를 신뢰할 수 없다. */
    private static final int MIN_DURATION_SEC = 20;

    /**
     * 위 시간에서 허용할 부족분.
     *
     * <p>앱은 정확히 20초를 재고, fps는 잰 값을 반올림해서 보낸다. 그래서 요구치인
     * fps×20이 실제 프레임 수보다 몇 장 많아지는 일이 생긴다 — 딱 맞게 잰 측정이
     * 반올림 한 번 때문에 통째로 거부됐다. 카메라가 프레임을 흘리는 것까지 감안하면
     * 여유가 필요하고, 이 앞단의 프레임 수 검사가 이미 30% 손실까지 받아 주므로
     * 여기만 무관용으로 둘 이유가 없다. 박자 수는 MIN_INTERVALS가 따로 지킨다.
     */
    private static final double DURATION_TOLERANCE = 0.9;

    /** 심박수 하한·상한(bpm). 이 밖은 사람의 안정시 심박으로 보지 않는다. */
    private static final double MIN_BPM = 40.0;
    private static final double MAX_BPM = 200.0;

    /** 통과시킬 주파수 대역(Hz). 0.7~3.5Hz = 42~210bpm. [튜닝 대상] */
    private static final double MIN_HZ = 0.7;
    private static final double MAX_HZ = 3.5;

    /**
     * 맥동 성분(AC)이 밝기 평균(DC) 대비 이 비율보다 작으면 손가락이 닿지 않은 것으로 본다.
     * 실제 카메라 PPG의 관류 지수는 보통 0.5~3%다. 지금은 "완전히 평평한 신호"만 걸러내도록
     * 아주 낮게 잡아 뒀다. 실측을 받으면 올려야 한다. [튜닝 대상]
     */
    private static final double MIN_PERFUSION = 0.001;

    /**
     * 피크 임계값. 신호의 <b>대표 진폭</b>에 이 배수를 곱한다.
     *
     * <p>대표 진폭을 RMS가 아니라 중앙값으로 잡는다. RMS는 큰 값 하나에 통째로 끌려간다.
     * 20초 중 0.3초짜리 흔들림 한 번이면 — 손가락을 고쳐 쥐거나 압력이 변하면 늘 생기는
     * 크기다 — RMS가 몇 배로 뛰고 임계값이 진짜 맥박 봉우리 전부보다 위로 올라간다.
     * 실제로 밝기 255단계 중 36단계짜리 흔들림 하나에 검출 피크가 24개에서 1개로
     * 떨어져 멀쩡한 측정이 통째로 거부됐다. 중앙값은 그런 값 하나에 꿈쩍하지 않는다.
     *
     * <p>기준이 바뀌었으니 배수도 다르다. RMS 시절의 0.7과 비교하지 말 것. [튜닝 대상]
     */
    /// 1.4에서 1.1까지 내렸다. 실기기 파형은 봉우리 높이가 박동마다 고르지 않아서,
    /// 문턱이 조금만 높아도 작은 박동이 통째로 안 잡힌다.
    ///
    /// <p>1.25로 되돌렸다가 다시 내렸다. 높이가 번갈아 크고 작은 파형(87bpm, 62fps)을
    /// 넣고 배수만 바꿔가며 재보니 <b>1.25에서 43.5bpm</b>이 나왔다 — 작은 박동을
    /// 하나 걸러 하나씩 건너뛰어 심박이 정확히 반토막 났다. 1.15 아래로는 전부
    /// 87.1bpm으로 맞았다. 절벽이 1.25와 1.15 사이에 있어서 1.1은 그 아래로
    /// 여유를 둔 값이다.
    ///
    /// <p>더 나쁜 건 반토막이 난 채로 <b>거부되지 않고 통과했다</b>는 점이다. 간격이
    /// 고르면 품질 판정을 지나가 버린다. 틀린 심박을 조용히 내놓느니 문턱을 낮춰
    /// 박동을 잡는 편이 낫다. 낮춰서 생기는 가짜 봉우리는 뒤의 불응기와 간격
    /// 이상치 제거가 한 번 더 거른다. [튜닝 대상]
    private static final double PEAK_THRESHOLD_RATIO = 1.1;

    /**
     * RR 간격이 중앙값에서 이 비율 이상 벗어나면 버린다. 움직임 때문에 튄 것으로 본다.
     *
     * <p><b>이 값은 함부로 올리면 안 된다.</b> 품질 등급이 "몇 개나 버렸는가"로 계산되기
     * 때문에, 여기를 느슨하게 하면 버려지는 게 줄어 잡음까지 양호로 보인다. 실제로
     * 0.45로 올렸더니 순수 잡음이 POOR에서 FAIR로 올라섰다. 통과를 넉넉하게 하고
     * 싶으면 아래 개수·비율 쪽을 건드려야 한다. [튜닝 대상]
     */
    private static final double MAX_RR_DEVIATION = 0.3;

    /**
     * 이 개수보다 적게 남으면 HRV를 낼 수 없다.
     *
     * <p>20초·72bpm이면 23개쯤 나온다. 8을 요구하면 셋 중 하나만 남아도 되는 셈이라
     * 넉넉해 보이지만, 피크를 절반 놓치는 상황과 겹치면 바로 걸린다. 6이면 HR 평균은
     * 충분히 안정적이고 HRV도 대략은 낸다 — 정확도가 떨어지는 건 품질 등급으로 알린다.
     */
    private static final int MIN_INTERVALS = 6;

    /**
     * 버려진 RR 비율이 이보다 크면 POOR, 그 아래 FAIR_REJECT_RATIO보다 크면 FAIR.
     *
     * <p>POOR는 측정을 통째로 버리고 다시 재라는 뜻이라 문턱이 높아야 한다. 0.3에서
     * 두 번 올렸다. 실기기에서 18초·16박을 제대로 잡은 측정이 <b>47% 버림</b>으로
     * 거부됐다 — 앞의 네 관문을 다 통과하고 마지막에서 7%p 차이로 떨어진 것이다.
     * 어두운 화면에서는 봉우리 높이가 들쭉날쭉해 간격이 그만큼 튀는 게 정상이고,
     * 그런 신호도 숫자를 내되 FAIR로 표시하는 편이 재측정을 반복시키는 것보다 낫다.
     *
     * <p>FAIR 문턱은 건드리지 않았다. GOOD과 FAIR을 가르는 선일 뿐 통과 여부와는
     * 무관해서 풀어도 얻는 게 없고, 올렸더니 4초간 크게 흔들린 측정까지 GOOD으로
     * 올라섰다. 흔들린 건 흔들렸다고 말해야 한다.
     */
    private static final double POOR_REJECT_RATIO = 0.55;
    private static final double FAIR_REJECT_RATIO = 0.1;

    @Override
    public SignalResult process(double[] samples, int fps) {
        if (samples == null
                || samples.length < (long) fps * MIN_DURATION_SEC * DURATION_TOLERANCE) {
            return SignalResult.poor("길이부족 n=%d".formatted(samples == null ? 0 : samples.length));
        }

        double[] filtered = bandpass(samples, fps);
        double perfusion = perfusion(samples, filtered);
        if (perfusion < MIN_PERFUSION) {
            return SignalResult.poor("관류부족 %.5f".formatted(perfusion));
        }

        double[] intervals = intervalsMs(detectPeaks(filtered, fps), fps);
        if (intervals.length < MIN_INTERVALS) {
            return SignalResult.poor(
                    "피크부족 %d개 관류=%.5f".formatted(intervals.length + 1, perfusion));
        }

        boolean[] kept = markUsable(intervals);
        int keptCount = countTrue(kept);
        if (keptCount < MIN_INTERVALS) {
            // 버려진 간격이 중앙값의 2배 근처면 박동을 놓친 것(임계값이 높다)이고,
            // 짧거나 제각각이면 없는 피크를 잡은 것(임계값이 낮다)이다. 원인이 정반대라
            // 최소·최대를 같이 봐야 어느 쪽인지 갈린다.
            return SignalResult.poor("간격이상 %d/%d 중앙%.0f 최소%.0f 최대%.0f"
                    .formatted(keptCount, intervals.length, median(intervals),
                            min(intervals), max(intervals)));
        }

        double meanRr = mean(intervals, kept);
        double hr = 60_000.0 / meanRr;
        if (hr < MIN_BPM || hr > MAX_BPM) {
            return SignalResult.poor("심박이상 %.0fbpm".formatted(hr));
        }

        double rejectRatio = 1.0 - ((double) keptCount / intervals.length);
        MeasurementQuality quality = judge(rejectRatio);

        return new SignalResult(
                round(hr),
                round(rmssd(intervals, kept)),
                round(sdnn(intervals, kept, meanRr)),
                quality,
                quality == MeasurementQuality.POOR
                        ? "간격흔들림 %.0f%% 버림 (%d/%d)"
                                .formatted(rejectRatio * 100, keptCount, intervals.length)
                        : "");
    }

    // ------------------------------------------------------------------
    // 1. 대역통과
    // ------------------------------------------------------------------

    /**
     * 이동평균 두 개의 차이로 대역통과를 만든다. IIR 필터와 달리 발산할 여지가 없고,
     * 창 길이만 보면 무엇을 걸러내는지 바로 읽힌다.
     */
    private double[] bandpass(double[] samples, int fps) {
        // 상한 주파수의 반주기만큼 평균 내면 그보다 빠른 성분이 죽는다.
        int smoothWindow = Math.max(1, (int) Math.round(fps / (2 * MAX_HZ)));
        // 하한 주파수의 한 주기만큼 평균 내면 그보다 느린 성분만 남는다. 그게 기저선이다.
        int baselineWindow = Math.max(3, (int) Math.round(fps / MIN_HZ));

        double[] smoothed = movingAverage(samples, smoothWindow);
        double[] baseline = movingAverage(samples, baselineWindow);

        double[] filtered = new double[samples.length];
        for (int i = 0; i < samples.length; i++) {
            filtered[i] = smoothed[i] - baseline[i];
        }
        return filtered;
    }

    /** 중심 이동평균. 누적합을 써서 창 길이와 무관하게 한 번만 훑는다. */
    private double[] movingAverage(double[] values, int window) {
        int half = window / 2;
        double[] prefix = new double[values.length + 1];
        for (int i = 0; i < values.length; i++) {
            prefix[i + 1] = prefix[i] + values[i];
        }

        double[] result = new double[values.length];
        for (int i = 0; i < values.length; i++) {
            int from = Math.max(0, i - half);
            int to = Math.min(values.length, i + half + 1);
            result[i] = (prefix[to] - prefix[from]) / (to - from);
        }
        return result;
    }

    // ------------------------------------------------------------------
    // 2. 관류 확인
    // ------------------------------------------------------------------

    /**
     * 관류 지수 — 맥동 성분이 밝기 대비 얼마나 되는가.
     *
     * <p>너무 작으면 손가락이 렌즈를 덮지 않았거나, 덮었는데 센서가 포화돼 맥동이
     * 잘려 나간 것이다. 판정만 하지 않고 값을 돌려주는 이유는, 거부됐을 때 이 숫자가
     * 얼마였는지가 다음에 무엇을 고칠지 알려주기 때문이다.
     */
    private double perfusion(double[] samples, double[] filtered) {
        double dc = mean(samples);
        return dc <= 0 ? 0 : rms(filtered) / dc;
    }

    // ------------------------------------------------------------------
    // 3~4. 피크 검출 + 포물선 보간
    // ------------------------------------------------------------------

    /**
     * 적응 임계값을 넘는 국소 최대점을 찾는다. 반환값은 <b>샘플 단위의 소수 위치</b>다.
     *
     * <p>불응기(최대 심박에 해당하는 간격)를 두어 한 박동의 이중 봉우리를 두 번 세지 않는다.
     * 불응기 안에서 더 큰 봉우리가 나오면 앞의 것을 그것으로 교체한다.
     */
    private double[] detectPeaks(double[] filtered, int fps) {
        double threshold = PEAK_THRESHOLD_RATIO * typicalAmplitude(filtered);
        int refractory = Math.max(1, (int) Math.round(fps * 60.0 / MAX_BPM));

        double[] positions = new double[filtered.length];
        int[] rawIndexes = new int[filtered.length];
        int count = 0;

        for (int i = 1; i < filtered.length - 1; i++) {
            boolean isLocalMax = filtered[i] >= filtered[i - 1] && filtered[i] > filtered[i + 1];
            if (!isLocalMax || filtered[i] <= threshold) {
                continue;
            }

            if (count > 0 && i - rawIndexes[count - 1] < refractory) {
                // 같은 박동 안이다. 더 높은 쪽만 남긴다.
                if (filtered[i] > filtered[rawIndexes[count - 1]]) {
                    rawIndexes[count - 1] = i;
                    positions[count - 1] = interpolate(filtered, i);
                }
                continue;
            }

            rawIndexes[count] = i;
            positions[count] = interpolate(filtered, i);
            count++;
        }

        return Arrays.copyOf(positions, count);
    }

    /**
     * 피크 좌우 세 점에 포물선을 맞춰 꼭짓점의 위치를 구한다.
     * 결과는 index ± 0.5 범위이며, 프레임 사이의 위치를 추정하는 것이 목적이다.
     */
    private double interpolate(double[] values, int index) {
        double left = values[index - 1];
        double center = values[index];
        double right = values[index + 1];

        double denominator = left - 2 * center + right;
        if (denominator == 0) {
            return index;
        }

        double delta = 0.5 * (left - right) / denominator;
        // 수치가 불안정하면 엉뚱한 데로 튄다. 한 프레임 밖으로는 못 나가게 막는다.
        if (delta < -0.5 || delta > 0.5) {
            return index;
        }
        return index + delta;
    }

    /** 피크 사이 간격을 밀리초로 바꾼다. */
    private double[] intervalsMs(double[] peaks, int fps) {
        if (peaks.length < 2) {
            return new double[0];
        }

        double[] intervals = new double[peaks.length - 1];
        for (int i = 1; i < peaks.length; i++) {
            intervals[i - 1] = (peaks[i] - peaks[i - 1]) / fps * 1000.0;
        }
        return intervals;
    }

    // ------------------------------------------------------------------
    // 5. 이상치 제거
    // ------------------------------------------------------------------

    /**
     * 쓸 만한 RR만 표시한다. 평균이 아니라 <b>중앙값</b>을 기준으로 삼는다.
     * 튄 값 몇 개가 평균을 끌고 가면 정상 간격이 이상치로 몰리기 때문이다.
     */
    private boolean[] markUsable(double[] intervals) {
        double median = median(intervals);
        double minRr = 60_000.0 / MAX_BPM;
        double maxRr = 60_000.0 / MIN_BPM;

        boolean[] kept = new boolean[intervals.length];
        for (int i = 0; i < intervals.length; i++) {
            double rr = intervals[i];
            kept[i] = rr >= minRr && rr <= maxRr
                    && Math.abs(rr - median) <= median * MAX_RR_DEVIATION;
        }
        return kept;
    }

    // ------------------------------------------------------------------
    // 6. 지표
    // ------------------------------------------------------------------

    /** RR 간격 전체의 표준편차. 컨디션 지수의 입력이다. */
    private double sdnn(double[] intervals, boolean[] kept, double meanRr) {
        double sum = 0;
        int count = 0;
        for (int i = 0; i < intervals.length; i++) {
            if (kept[i]) {
                double d = intervals[i] - meanRr;
                sum += d * d;
                count++;
            }
        }
        return count < 2 ? 0.0 : Math.sqrt(sum / (count - 1));
    }

    /**
     * 인접 RR 차이의 제곱평균제곱근. 화면에 "HRV"로 보여주는 값이다.
     *
     * <p><b>연속으로 살아남은 쌍만 센다.</b> 가운데를 버린 자리를 건너뛰고 차이를 구하면
     * 실제로는 두 박동 떨어진 간격을 인접한 것처럼 계산하게 되어 값이 부풀려진다.
     */
    private Double rmssd(double[] intervals, boolean[] kept) {
        double sum = 0;
        int count = 0;
        for (int i = 1; i < intervals.length; i++) {
            if (kept[i] && kept[i - 1]) {
                double d = intervals[i] - intervals[i - 1];
                sum += d * d;
                count++;
            }
        }
        return count == 0 ? null : Math.sqrt(sum / count);
    }

    private MeasurementQuality judge(double rejectRatio) {
        if (rejectRatio > POOR_REJECT_RATIO) {
            return MeasurementQuality.POOR;
        }
        if (rejectRatio > FAIR_REJECT_RATIO) {
            return MeasurementQuality.FAIR;
        }
        return MeasurementQuality.GOOD;
    }

    // ------------------------------------------------------------------
    // 계산 도우미
    // ------------------------------------------------------------------

    private double mean(double[] values) {
        double sum = 0;
        for (double value : values) {
            sum += value;
        }
        return values.length == 0 ? 0 : sum / values.length;
    }

    private double mean(double[] values, boolean[] kept) {
        double sum = 0;
        int count = 0;
        for (int i = 0; i < values.length; i++) {
            if (kept[i]) {
                sum += values[i];
                count++;
            }
        }
        return count == 0 ? 0 : sum / count;
    }

    /**
     * 신호의 대표 진폭. 절대값의 중앙값을 쓴다.
     *
     * <p>평균이나 RMS를 쓰지 않는 이유는 이 값이 <b>임계값의 기준</b>이기 때문이다.
     * 20초 중 0.3초가 크게 튀면 RMS는 몇 배가 되지만 중앙값은 거의 그대로다. 임계값은
     * 나머지 19.7초의 맥박을 잡으라고 있는 것이므로, 튄 구간이 기준을 정하면 안 된다.
     *
     * <p>맥박 파형은 대부분의 시간을 0 근처에서 보내고 봉우리에서만 커진다. 그래서
     * 중앙값은 봉우리 높이보다 한참 작고, 위 배수는 그 점을 감안한 값이다.
     */
    private double typicalAmplitude(double[] values) {
        if (values.length == 0) {
            return 0;
        }
        double[] magnitudes = new double[values.length];
        for (int i = 0; i < values.length; i++) {
            magnitudes[i] = Math.abs(values[i]);
        }
        return median(magnitudes);
    }

    private double rms(double[] values) {
        double sum = 0;
        for (double value : values) {
            sum += value * value;
        }
        return values.length == 0 ? 0 : Math.sqrt(sum / values.length);
    }

    private double min(double[] values) {
        double smallest = Double.MAX_VALUE;
        for (double value : values) {
            smallest = Math.min(smallest, value);
        }
        return values.length == 0 ? 0 : smallest;
    }

    private double max(double[] values) {
        double largest = 0;
        for (double value : values) {
            largest = Math.max(largest, value);
        }
        return largest;
    }

    private double median(double[] values) {
        double[] sorted = values.clone();
        Arrays.sort(sorted);
        int mid = sorted.length / 2;
        return (sorted.length % 2 == 0) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
    }

    private int countTrue(boolean[] flags) {
        int count = 0;
        for (boolean flag : flags) {
            if (flag) {
                count++;
            }
        }
        return count;
    }

    /** 소수점 한 자리. 카메라 PPG의 정확도로 그 아래 자릿수는 의미가 없다. */
    private Double round(Double value) {
        return value == null ? null : Math.round(value * 10.0) / 10.0;
    }
}
