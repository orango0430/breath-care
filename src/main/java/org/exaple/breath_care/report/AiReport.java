package org.exaple.breath_care.report;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.exaple.breath_care.global.persistence.StringListConverter;
import org.exaple.breath_care.report.generate.ReportContent;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * 생성해 둔 AI 리포트.
 *
 * <p><b>저장하는 이유는 조회 편의가 아니라 비용이다.</b> 같은 기간의 리포트를 다시 열 때
 * 저장된 걸 그대로 돌려주면 Gemini 호출이 0이 된다. (user_id, period_start) 유니크 제약이 그 근거다.
 */
@Entity
@Table(name = "ai_report")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AiReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    /** 집계 구간 시작일 (포함). 한국 시간 기준 날짜다. */
    @Column(nullable = false)
    private LocalDate periodStart;

    /** 집계 구간 종료일 (포함) */
    @Column(nullable = false)
    private LocalDate periodEnd;

    @Column(nullable = false, length = 500)
    private String summary;

    @Convert(converter = StringListConverter.class)
    @Column(nullable = false, columnDefinition = "TEXT")
    private List<String> insights;

    @Convert(converter = StringListConverter.class)
    @Column(nullable = false, columnDefinition = "TEXT")
    private List<String> advice;

    /** 생성에 쓴 모델. 모델을 갈아탄 뒤 예전 리포트 품질을 비교하려면 남겨야 한다. */
    @Column(nullable = false, length = 50)
    private String model;

    @Column(nullable = false)
    private Instant generatedAt;

    private AiReport(Long userId, LocalDate periodStart, LocalDate periodEnd,
                     ReportContent content, String model, Instant generatedAt) {
        this.userId = userId;
        this.periodStart = periodStart;
        this.periodEnd = periodEnd;
        this.model = model;
        this.generatedAt = generatedAt;
        apply(content);
    }

    public static AiReport create(Long userId, LocalDate periodStart, LocalDate periodEnd,
                                  ReportContent content, String model, Instant generatedAt) {
        return new AiReport(userId, periodStart, periodEnd, content, model, generatedAt);
    }

    /** 같은 기간을 다시 생성했을 때. 행을 새로 만들지 않고 덮어써서 기간당 하나를 유지한다. */
    public void regenerate(ReportContent content, String model, Instant generatedAt) {
        this.model = model;
        this.generatedAt = generatedAt;
        apply(content);
    }

    private void apply(ReportContent content) {
        this.summary = content.summary();
        this.insights = content.insights();
        this.advice = content.advice();
    }
}
