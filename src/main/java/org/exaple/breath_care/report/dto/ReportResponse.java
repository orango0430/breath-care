package org.exaple.breath_care.report.dto;

import org.exaple.breath_care.report.AiReport;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * 시안의 "AI 분석 · 현재 상태" 카드에 대응한다.
 * summary가 강조 박스 한 줄, insights와 advice가 그 아래 문단들이다.
 *
 * @param disclaimer 시안 맨 아래 작은 글씨. 모델이 만든 문장이 아니라 서버가 고정으로 내려준다.
 *                   건강 관련 문구라 표현을 바꿔야 할 때 앱을 다시 배포하지 않고 고칠 수 있어야 한다
 * @param cached     true면 저장돼 있던 걸 그대로 준 것이다. 즉 이번 요청으로 Gemini를 부르지 않았다.
 *                   앱이 "새로 만들기" 버튼을 살릴지 말지 판단하는 데 쓴다
 */
public record ReportResponse(
        LocalDate periodStart,
        LocalDate periodEnd,
        String summary,
        List<String> insights,
        List<String> advice,
        String disclaimer,
        String model,
        Instant generatedAt,
        boolean cached
) {
    private static final String DISCLAIMER =
            "이 리포트는 측정값을 바탕으로 만든 참고 정보이며 의학적 진단이 아니에요. "
                    + "몸에 이상이 느껴지면 전문가와 상담해 주세요.";

    public static ReportResponse of(AiReport report, boolean cached) {
        return new ReportResponse(
                report.getPeriodStart(),
                report.getPeriodEnd(),
                report.getSummary(),
                report.getInsights(),
                report.getAdvice(),
                DISCLAIMER,
                report.getModel(),
                report.getGeneratedAt(),
                cached);
    }
}
