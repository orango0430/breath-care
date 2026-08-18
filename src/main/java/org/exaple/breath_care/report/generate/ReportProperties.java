package org.exaple.breath_care.report.generate;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 어느 제공자를 쓰든 똑같이 적용되는 리포트 설정.
 *
 * <p>사용량을 아끼는 규칙은 제공자와 무관한 우리 정책이므로 여기 둔다.
 * 제공자를 갈아타도 캐시·쿨다운·최소 측정 수는 그대로 따라간다.
 *
 * @param provider                {@code none | gemini | openai}. 켜진 제공자 하나만 빈으로 뜬다.
 *                                none이면 리포트만 503이 되고 나머지 기능은 그대로 동작한다
 * @param minMeasurements         이 수보다 측정이 적으면 호출하지 않고 막는다
 * @param regenerateCooldownHours 강제 재생성 최소 간격
 * @param maxOutputTokens         출력 상한. 길게 쓰라고 둘 이유가 없다
 */
@ConfigurationProperties(prefix = "report")
public record ReportProperties(
        String provider,
        int minMeasurements,
        int regenerateCooldownHours,
        int maxOutputTokens,
        int timeoutSeconds
) {
}
