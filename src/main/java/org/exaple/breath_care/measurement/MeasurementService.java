package org.exaple.breath_care.measurement;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.measurement.dto.GuestMeasurementRequest;
import org.exaple.breath_care.measurement.dto.GuestMeasurementResponse;
import org.exaple.breath_care.measurement.dto.MeasurementRequest;
import org.exaple.breath_care.measurement.dto.MeasurementResponse;
import org.exaple.breath_care.measurement.score.ConditionScoreCalculator;
import org.exaple.breath_care.measurement.signal.SignalProcessor;
import org.exaple.breath_care.measurement.signal.SignalResult;
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
    private final RejectedSignalRecorder rejectedSignalRecorder;
    private final SignalProcessor signalProcessor;

    @Transactional
    public MeasurementResponse measure(Long userId, MeasurementRequest request) {
        SignalResult result = process(userId, request.samples(), request.fps(), request.durationSec());
        Double conditionScore = ConditionScoreCalculator.score(result.hrvSdnn());

        Measurement measurement = measurementRepository.save(Measurement.create(
                userId, result.hr(), result.hrv(), result.hrvSdnn(),
                conditionScore, result.quality(), Instant.now()));

        signalRepository.save(new MeasurementSignal(
                measurement.getId(), request.fps(), request.durationSec(), join(request.samples())));

        return MeasurementResponse.from(measurement);
    }

    /**
     * 비회원 측정. <b>계산만 하고 아무것도 저장하지 않는다.</b>
     *
     * <p>회원과 완전히 같은 신호처리·점수 계산을 거친다. 구현이 하나여야 가입 전후로
     * 숫자가 달라지지 않고, 알고리즘을 고칠 때 앱 업데이트도 필요 없다.
     *
     * <p>컨디션 지수는 이번 측정의 HRV만으로 나오므로 과거 이력이 필요 없다.
     * 그래서 비회원도 회원과 똑같은 값을 받는다.
     *
     * <p>성공한 측정은 아무것도 남기지 않으므로 트랜잭션을 열지 않는다. 거부된 파형만
     * 예외다 — 그건 {@link RejectedSignalRecorder}가 자기 트랜잭션에서 따로 남긴다.
     */
    public GuestMeasurementResponse analyze(GuestMeasurementRequest request) {
        // 비회원이라 붙일 사용자가 없다. 파형 자체는 회원 것과 똑같이 쓸모가 있다.
        SignalResult result = process(null, request.samples(), request.fps(), request.durationSec());

        return new GuestMeasurementResponse(
                result.hr(), result.hrv(), ConditionScoreCalculator.score(result.hrvSdnn()),
                result.quality(), Instant.now());
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
    private SignalResult process(Long userId, List<Double> samples, int fps, int durationSec) {
        if (hasTooFewFrames(samples, fps, durationSec)) {
            rejectedSignalRecorder.record(userId, fps, durationSec, samples, "TOO_FEW_FRAMES");
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY,
                    "측정 중 프레임이 많이 누락됐어요. 다시 측정해 주세요.");
        }

        SignalResult result = signalProcessor.process(toArray(samples), fps);
        if (!result.isUsable()) {
            rejectedSignalRecorder.record(userId, fps, durationSec, samples, result.note());
            // 사유를 그대로 내보낸다. 폰에는 붙일 디버거가 없어서, 이 줄이 아니면
            // 어느 단계에서 걸렸는지 알 방법이 없다. 파형 값 자체는 담기지 않는다.
            throw new BusinessException(ErrorCode.POOR_SIGNAL_QUALITY,
                    "신호 품질이 낮습니다. 다시 측정해 주세요. (%s)".formatted(result.note()));
        }

        return result;
    }

    /** fps × 측정시간만큼 프레임이 왔는지 본다. 카메라가 버벅이면 여기서 걸린다. */
    private boolean hasTooFewFrames(List<Double> samples, int fps, int durationSec) {
        long expected = (long) fps * durationSec;
        return samples.size() < expected * MIN_FRAME_RATIO;
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
