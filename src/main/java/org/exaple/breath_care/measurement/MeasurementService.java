package org.exaple.breath_care.measurement;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
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
        double[] samples = toArray(request.samples());

        if (hasTooFewFrames(request)) {
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY,
                    "측정 중 프레임이 많이 누락됐어요. 다시 측정해 주세요.");
        }

        SignalResult result = signalProcessor.process(samples, request.fps());
        if (!result.isUsable()) {
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY);
        }

        // 이번 측정은 기준선에 넣지 않는다. 자기 자신과 비교하면 편차가 줄어든다.
        Double stressScore = StressScoreCalculator.score(result.hr(), baselineOf(userId));

        Measurement measurement = measurementRepository.save(Measurement.create(
                userId, result.hr(), result.hrv(), stressScore, result.quality(), Instant.now()));

        signalRepository.save(new MeasurementSignal(
                measurement.getId(), request.fps(), request.durationSec(), join(request.samples())));

        return MeasurementResponse.from(measurement);
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

    /** fps × 측정시간만큼 프레임이 왔는지 본다. 카메라가 버벅이면 여기서 걸린다. */
    private boolean hasTooFewFrames(MeasurementRequest request) {
        long expected = (long) request.fps() * request.durationSec();
        return request.samples().size() < expected * MIN_FRAME_RATIO;
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
