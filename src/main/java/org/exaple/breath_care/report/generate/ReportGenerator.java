package org.exaple.breath_care.report.generate;

/**
 * 리포트 본문 생성기.
 *
 * <p>구현이 둘이다. 키가 있으면 {@link GeminiReportGenerator}, 없으면 {@link DisabledReportGenerator}가
 * 뜬다. 덕분에 키가 없는 팀원도 앱을 그대로 실행할 수 있고, 리포트만 503으로 막힌다.
 */
public interface ReportGenerator {

    ReportContent generate(ReportInput input);

    /** 생성에 쓴 모델 이름. 리포트에 기록해 두려고 받는다. */
    String modelName();
}
