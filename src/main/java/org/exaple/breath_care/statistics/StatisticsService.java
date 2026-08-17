package org.exaple.breath_care.statistics;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementRepository;
import org.exaple.breath_care.statistics.dto.DailyMetric;
import org.exaple.breath_care.statistics.dto.MetricSummary;
import org.exaple.breath_care.statistics.dto.StatisticsSummaryResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 측정 이력 집계.
 *
 * <p>SQL로 날짜 그룹핑을 하려면 시간대 변환 함수가 필요한데 DB마다 문법이 달라진다.
 * 한 사용자의 한 주 분량은 많아야 수십 건이라, 불러와서 자바에서 묶는 편이 단순하고 이식성도 좋다.
 */
@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final MeasurementRepository measurementRepository;

    @Transactional(readOnly = true)
    public StatisticsSummaryResponse summary(Long userId, Instant from, Instant to) {
        return summary(userId, DayRange.of(from, to));
    }

    /**
     * 구간을 이미 정해 둔 호출자용. AI 리포트는 요약과 일별을 같은 구간으로 묶어야 해서,
     * Instant를 넘겨 양쪽에서 따로 날짜로 환산하면 자정 근처에서 구간이 어긋날 수 있다.
     */
    @Transactional(readOnly = true)
    public StatisticsSummaryResponse summary(Long userId, DayRange range) {
        List<Measurement> measurements = measurementsIn(userId, range);

        return new StatisticsSummaryResponse(
                range.from(),
                range.to(),
                measurements.size(),
                MetricSummary.of(valuesOf(measurements, Measurement::getHr)),
                MetricSummary.of(valuesOf(measurements, Measurement::getHrv)),
                MetricSummary.of(valuesOf(measurements, Measurement::getStressScore)));
    }

    @Transactional(readOnly = true)
    public List<DailyMetric> daily(Long userId, Instant from, Instant to) {
        return daily(userId, DayRange.of(from, to));
    }

    @Transactional(readOnly = true)
    public List<DailyMetric> daily(Long userId, DayRange range) {
        Map<LocalDate, List<Measurement>> byDate = measurementsIn(userId, range).stream()
                .collect(Collectors.groupingBy(m -> range.dateOf(m.getMeasuredAt())));

        return range.eachDay().stream()
                .map(date -> averageOf(date, byDate.get(date)))
                .toList();
    }

    private DailyMetric averageOf(LocalDate date, List<Measurement> measurements) {
        if (measurements == null || measurements.isEmpty()) {
            return DailyMetric.empty(date);
        }

        return new DailyMetric(
                date,
                MetricSummary.of(valuesOf(measurements, Measurement::getHr)).avg(),
                MetricSummary.of(valuesOf(measurements, Measurement::getHrv)).avg(),
                MetricSummary.of(valuesOf(measurements, Measurement::getStressScore)).avg(),
                measurements.size());
    }

    private List<Measurement> measurementsIn(Long userId, DayRange range) {
        return measurementRepository.findInRange(userId, range.startInstant(), range.endInstantExclusive());
    }

    private List<Double> valuesOf(List<Measurement> measurements, Function<Measurement, Double> metric) {
        return measurements.stream().map(metric).toList();
    }
}
