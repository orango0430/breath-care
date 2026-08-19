package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.statistics.dto.DailyMetric;
import org.exaple.breath_care.statistics.dto.MetricSummary;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * 프롬프트 조립. 생성기에서 떼어 둔 이유는 문구를 손볼 때 호출 코드를 건드리지 않기 위해서다.
 */
final class ReportPrompt {

    private ReportPrompt() {
    }

    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("MM-dd");
    private static final String NONE = "-";

    /**
     * 지표 방향을 못 박아 두지 않으면 HRV를 거꾸로 해석한다.
     * "HRV가 낮아져서 좋아졌다"는 문장이 리포트에 나오면 앱 전체 신뢰가 무너진다.
     *
     * <p>V14에서 스트레스 지수(높을수록 긴장)를 컨디션 지수(높을수록 좋음)로 바꿨다.
     * <b>방향이 정반대다.</b> 이 문구를 안 고치면 컨디션 96점을 받은 사용자에게
     * "긴장도가 매우 높습니다"라고 쓴다.
     */
    static final String SYSTEM_INSTRUCTION = """
            너는 호흡 케어 앱 '숨:케어'의 주간 리포트를 쓰는 코치다.

            [지표 해석 규칙]
            - 심박수(bpm): 낮을수록 안정
            - HRV(ms): 높을수록 안정. 심박수와 방향이 반대다
            - 컨디션 지수(0~100): 이 앱이 HRV로 계산한 값. 높을수록 좋다.
              심박수와 방향이 반대이고 HRV와 같은 방향이다. 낮은 점수를 좋다고 쓰지 마라
            - 값이 '-'이면 그 날은 측정이 없다. 없는 날을 추측해서 쓰지 마라

            [작성 규칙]
            - 한국어 존댓말, 담백하고 다정한 어조
            - 진단명·질병명·치료법을 쓰지 마라. 걱정되는 신호가 보이면 전문가 상담 권유까지만
            - 주어진 숫자로 확인되지 않는 사실을 지어내지 마라
            - 호흡 세션은 '리추얼'이라고 부른다. 앱 안에서 쓰는 말이다
            - 기간은 '이번 주'로 지칭한다
            - summary는 한 문장. 화면 맨 위에 크게 걸리는 문장이라 그 자체로 말이 돼야 한다
            - insights는 3개. 각각 한국어 60~90자의 완결된 문장. 관찰된 내용만 쓴다
            - advice는 1~2개. 각각 한국어 60~90자의 완결된 문장. 바로 할 수 있는 것만 쓴다
            - insights와 advice에는 실제 숫자를 넣어라.
              "평균 심박수는 82.0 BPM으로" 처럼 위에 준 값을 그대로 인용한다
            """;

    static String userContent(ReportInput input) {
        StringBuilder sb = new StringBuilder();

        sb.append("기간: ").append(input.from()).append(" ~ ").append(input.to())
                .append(" (측정 ").append(input.measurementCount()).append("회)\n");
        appendSummary(sb, "심박수", input.hr());
        appendSummary(sb, "HRV", input.hrv());
        appendSummary(sb, "컨디션 지수", input.conditionScore());

        sb.append("\n일별 (날짜 / 심박수 / HRV / 컨디션 지수 / 측정횟수)\n");
        for (DailyMetric day : input.daily()) {
            sb.append(day.date().format(DAY)).append(' ')
                    .append(num(day.hr())).append(' ')
                    .append(num(day.hrv())).append(' ')
                    .append(num(day.conditionScore())).append(' ')
                    .append(day.measurementCount()).append('\n');
        }

        return sb.toString();
    }

    /** 모델이 낼 JSON 구조. 필드가 빠지거나 이름이 달라지는 일을 원천 차단한다. */
    static GeminiApi.Schema responseSchema() {
        return GeminiApi.Schema.object(
                Map.of(
                        "summary", GeminiApi.Schema.string(),
                        "insights", GeminiApi.Schema.arrayOfString(),
                        "advice", GeminiApi.Schema.arrayOfString()),
                List.of("summary", "insights", "advice"));
    }

    private static void appendSummary(StringBuilder sb, String label, MetricSummary metric) {
        if (metric == null || metric.count() == 0) {
            sb.append(label).append(": 기록 없음\n");
            return;
        }
        sb.append(label)
                .append(": 평균 ").append(num(metric.avg()))
                .append(" / 최고 ").append(num(metric.max()))
                .append(" / 최소 ").append(num(metric.min()))
                .append('\n');
    }

    /** 소수점 한 자리면 충분하다. 자릿수를 늘려 봐야 토큰만 먹고 리포트 문장은 달라지지 않는다. */
    private static String num(Double value) {
        return (value == null) ? NONE : String.format("%.1f", value);
    }
}
