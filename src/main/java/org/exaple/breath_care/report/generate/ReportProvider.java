package org.exaple.breath_care.report.generate;

/**
 * {@code report.provider} 값. 조건부 빈 등록에 쓰는 문자열을 한곳에 모아 둔다.
 *
 * <p>제공자별로 {@code enabled} 불리언을 따로 두면 둘 다 true가 됐을 때
 * {@link ReportGenerator} 빈이 둘이 되어 앱이 뜨지 않는다. 하나만 고르게 만든 이유다.
 */
public final class ReportProvider {

    private ReportProvider() {
    }

    /** 설정 키. {@code @ConditionalOnProperty}에 그대로 쓴다. */
    public static final String KEY = "report.provider";

    public static final String GEMINI = "gemini";
    public static final String OPENAI = "openai";
    /** 키가 없는 팀원·CI용 기본값. 리포트만 503이 되고 나머지는 그대로 동작한다. */
    public static final String NONE = "none";
}
