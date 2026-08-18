package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Gemini 키가 없을 때 대신 뜬다.
 *
 * <p>리포트만 503으로 막히고 측정·통계·알림은 그대로 동작한다.
 * 키를 못 받은 팀원이 앱을 못 띄우는 상황을 만들지 않기 위한 것이다.
 *
 * <p>{@code report.provider}를 아예 적지 않은 경우도 여기로 온다. 기본값이 "안 씀"이어야
 * 설정을 깜빡한 환경에서 엉뚱한 제공자로 호출이 나가는 일이 없다.
 */
@Component
@ConditionalOnProperty(name = ReportProvider.KEY, havingValue = ReportProvider.NONE, matchIfMissing = true)
public class DisabledReportGenerator implements ReportGenerator {

    private static final String DISABLED = "disabled";

    @Override
    public ReportContent generate(ReportInput input) {
        throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
    }

    @Override
    public String modelName() {
        return DISABLED;
    }
}
