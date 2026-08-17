package org.exaple.breath_care.report.generate;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Gemini 설정. 전부 application.yml의 {@code gemini.*}에서 온다.
 *
 * @param apiKey                  절대 커밋하지 않는다. 환경변수 GEMINI_API_KEY로만 주입한다
 * @param model                   모델 이름. 코드가 아니라 설정이라 갈아탈 때 재배포만 하면 된다
 * @param minMeasurements         이 수보다 측정이 적으면 호출하지 않고 막는다
 * @param regenerateCooldownHours 강제 재생성 최소 간격
 * @param maxOutputTokens         출력 상한. 길게 쓰라고 둘 이유가 없다
 */
@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(
        boolean enabled,
        String apiKey,
        String model,
        int minMeasurements,
        int regenerateCooldownHours,
        int maxOutputTokens,
        int timeoutSeconds
) {
}
