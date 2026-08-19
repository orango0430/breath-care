package org.exaple.breath_care.report;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.report.dto.ReportResponse;
import org.exaple.breath_care.report.generate.ReportContent;
import org.exaple.breath_care.report.generate.ReportGenerator;
import org.exaple.breath_care.report.generate.ReportInput;
import org.exaple.breath_care.report.generate.ReportProperties;
import org.exaple.breath_care.statistics.DayRange;
import org.exaple.breath_care.statistics.StatisticsService;
import org.exaple.breath_care.statistics.dto.StatisticsSummaryResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/**
 * 주간 AI 리포트.
 *
 * <p><b>이 클래스의 목적 절반은 AI를 부르지 않는 것이다.</b> 한도·크레딧을 지키려고
 * 호출 앞에 관문을 넷 세워 뒀다.
 *
 * <ol>
 *   <li>조회({@code GET})는 저장된 것만 준다. 없으면 404다. 조회로는 결코 호출이 일어나지 않는다</li>
 *   <li>생성({@code POST})도 같은 기간 리포트가 이미 있으면 저장된 걸 그대로 준다</li>
 *   <li>측정이 {@code report.min-measurements}회 미만이면 호출하지 않고 막는다.
 *       측정 한두 건으로 만든 리포트는 쓸 내용도 없으면서 호출만 축낸다</li>
 *   <li>강제 재생성은 {@code report.regenerate-cooldown-hours} 간격을 둔다.
 *       버튼 연타로 한도가 녹는 걸 막는다</li>
 * </ol>
 *
 * <p>결과적으로 한 사용자가 하루에 쓸 수 있는 호출은 많아야
 * {@code 24 / regenerate-cooldown-hours}회다. 기본값 6시간이면 4회다.
 */
@Service
@RequiredArgsConstructor
public class ReportService {

    private final AiReportRepository aiReportRepository;
    private final StatisticsService statisticsService;
    private final ReportGenerator reportGenerator;
    private final ReportProperties reportProperties;

    /** 저장된 리포트만 조회한다. 없으면 404. 이 경로에서는 AI를 부르지 않는다. */
    @Transactional(readOnly = true)
    public ReportResponse find(Long userId) {
        DayRange range = currentWeek();

        return aiReportRepository.findByUserIdAndPeriodStart(userId, range.from())
                .map(report -> ReportResponse.of(report, true))
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "아직 이번 주 리포트가 없어요."));
    }

    /**
     * 이번 주 리포트를 생성한다.
     *
     * @param refresh 이미 있는 리포트를 다시 만들지 여부. 쿨다운이 지나지 않았으면 무시하고 기존 것을 준다
     */
    @Transactional
    public ReportResponse generate(Long userId, boolean refresh) {
        DayRange range = currentWeek();
        Optional<AiReport> existing = aiReportRepository.findByUserIdAndPeriodStart(userId, range.from());

        if (existing.isPresent() && !canRegenerate(existing.get(), refresh)) {
            return ReportResponse.of(existing.get(), true);
        }

        ReportInput input = collect(userId, range);
        requireEnoughData(input);

        ReportContent content = reportGenerator.generate(input);
        Instant now = Instant.now();

        AiReport report = existing
                .map(saved -> {
                    saved.regenerate(content, reportGenerator.modelName(), now);
                    return saved;
                })
                .orElseGet(() -> aiReportRepository.save(AiReport.create(
                        userId, range.from(), range.to(), content, reportGenerator.modelName(), now)));

        return ReportResponse.of(report, false);
    }

    /** 오늘 포함 최근 7일. 기간을 앱이 정하게 두면 하루씩 밀어 가며 매번 새 리포트를 만들 수 있다. */
    private DayRange currentWeek() {
        return DayRange.of(null, null);
    }

    private boolean canRegenerate(AiReport report, boolean refresh) {
        if (!refresh) {
            return false;
        }
        Duration cooldown = Duration.ofHours(reportProperties.regenerateCooldownHours());
        return report.getGeneratedAt().plus(cooldown).isBefore(Instant.now());
    }

    private ReportInput collect(Long userId, DayRange range) {
        StatisticsSummaryResponse summary = statisticsService.summary(userId, range);

        return new ReportInput(
                range.from(),
                range.to(),
                summary.measurementCount(),
                summary.hr(),
                summary.hrv(),
                summary.conditionScore(),
                statisticsService.daily(userId, range));
    }

    private void requireEnoughData(ReportInput input) {
        int required = reportProperties.minMeasurements();
        if (input.measurementCount() < required) {
            throw new BusinessException(ErrorCode.INSUFFICIENT_DATA,
                    "리포트를 만들려면 이번 주 측정이 %d회 이상 필요해요. (현재 %d회)"
                            .formatted(required, input.measurementCount()));
        }
    }
}
