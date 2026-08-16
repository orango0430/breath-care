package org.exaple.breath_care.measurement;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.measurement.dto.BaselineResponse;
import org.exaple.breath_care.measurement.dto.GuestMeasurementRequest;
import org.exaple.breath_care.measurement.dto.GuestMeasurementResponse;
import org.exaple.breath_care.measurement.dto.MeasurementRequest;
import org.exaple.breath_care.measurement.dto.MeasurementResponse;
import org.exaple.breath_care.measurement.score.Baseline;
import org.exaple.breath_care.measurement.score.StressScoreCalculator;
import org.exaple.breath_care.measurement.signal.SignalProcessor;
import org.exaple.breath_care.measurement.signal.SignalResult;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.StringJoiner;

@Service
@RequiredArgsConstructor
public class MeasurementService {

    /** 실제 프레임이 기대치의 이 비율보다 적으면 프레임 드랍이 심해 신뢰할 수 없다. */
    private static final double MIN_FRAME_RATIO = 0.7;

    private final MeasurementRepository measurementRepository;
    private final MeasurementSignalRepository signalRepository;
    private final SignalProcessor signalProcessor;

    @Transactional
    public MeasurementResponse measure(Long userId, MeasurementRequest request) {
        SignalResult result = process(request.samples(), request.fps(), request.durationSec());

        // 이번 측정은 기준선에 넣지 않는다. 자기 자신과 비교하면 편차가 줄어든다.
        Double stressScore = StressScoreCalculator.score(result.hr(), baselineOf(userId));

        Measurement measurement = measurementRepository.save(Measurement.create(
                userId, result.hr(), result.hrv(), stressScore, result.quality(), Instant.now()));

        signalRepository.save(new MeasurementSignal(
                measurement.getId(), request.fps(), request.durationSec(), join(request.samples())));

        return MeasurementResponse.from(measurement);
    }

    /**
     * 비회원 측정. <b>계산만 하고 아무것도 저장하지 않는다.</b>
     *
     * <p>비회원의 이력은 폰에만 있으므로 기준선 재료를 요청에서 받는다. 그 점만 빼면
     * 회원과 완전히 같은 신호처리·점수 계산을 거친다. 구현이 하나여야 가입 전후로
     * 숫자가 달라지지 않고, 알고리즘을 고칠 때 앱 업데이트도 필요 없다.
     *
     * <p>DB를 건드리지 않으므로 트랜잭션도 열지 않는다.
     */
    public GuestMeasurementResponse analyze(GuestMeasurementRequest request) {
        SignalResult result = process(request.samples(), request.fps(), request.durationSec());

        Baseline baseline = StressScoreCalculator.baselineOf(recentWindow(request.recentHrs()));
        Double stressScore = StressScoreCalculator.score(result.hr(), baseline);

        return new GuestMeasurementResponse(
                result.hr(), result.hrv(), stressScore, result.quality(),
                Instant.now(), BaselineResponse.from(baseline));
    }

    /** 최근 측정들로 만든 개인 기준선. 표본이 모자라면 아직 준비되지 않은 상태로 나온다. */
    @Transactional(readOnly = true)
    public Baseline baselineOf(Long userId) {
        List<Double> recentHrs = measurementRepository.findRecentHr(
                userId, PageRequest.of(0, StressScoreCalculator.BASELINE_WINDOW));

        return StressScoreCalculator.baselineOf(recentHrs);
    }

    @Transactional(readOnly = true)
    public List<MeasurementResponse> findInRange(Long userId, Instant from, Instant to) {
        return measurementRepository.findInRange(userId, from, to).stream()
                .map(MeasurementResponse::from)
                .toList();
    }

    /**
     * 품질 검사 + 신호처리. 회원·비회원이 같은 경로를 지난다.
     * 나쁜 데이터로 낸 숫자를 보여주느니 다시 재게 하는 편이 낫다.
     */
    private SignalResult process(List<Double> samples, int fps, int durationSec) {
        if (hasTooFewFrames(samples, fps, durationSec)) {
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY,
                    "측정 중 프레임이 많이 누락됐어요. 다시 측정해 주세요.");
        }

        SignalResult result = signalProcessor.process(toArray(samples), fps);
        if (!result.isUsable()) {
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY);
        }

        return result;
    }

    /** fps × 측정시간만큼 프레임이 왔는지 본다. 카메라가 버벅이면 여기서 걸린다. */
    private boolean hasTooFewFrames(List<Double> samples, int fps, int durationSec) {
        long expected = (long) fps * durationSec;
        return samples.size() < expected * MIN_FRAME_RATIO;
    }

    /**
     * 앱이 보낸 이력에서 기준선에 쓸 만큼만 잘라 낸다.
     * 최신순으로 온다고 보고 앞에서 자르므로, 오래된 컨디션에 끌려가지 않는다.
     */
    private List<Double> recentWindow(List<Double> recentHrs) {
        if (recentHrs == null || recentHrs.isEmpty()) {
            return List.of();
        }

        return recentHrs.subList(0, Math.min(recentHrs.size(), StressScoreCalculator.BASELINE_WINDOW));
    }

    private double[] toArray(List<Double> samples) {
        double[] values = new double[samples.size()];
        for (int i = 0; i < values.length; i++) {
            values[i] = samples.get(i);
        }
        return values;
    }

    private String join(List<Double> samples) {
        StringJoiner joiner = new StringJoiner(",");
        samples.forEach(value -> joiner.add(String.valueOf(value)));
        return joiner.toString();
    }
}
