package org.exaple.breath_care.report.generate;

import java.util.List;

/**
 * 생성된 리포트 본문.
 *
 * @param summary  한두 문장 요약. 앱 상단에 크게 보여주는 문장이다
 * @param insights 관찰된 패턴. "무슨 일이 있었는지"
 * @param advice   실행 제안. "그래서 뭘 하면 되는지"
 */
public record ReportContent(String summary, List<String> insights, List<String> advice) {
}
