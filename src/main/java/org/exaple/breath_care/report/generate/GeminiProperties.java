package org.exaple.breath_care.report.generate;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Gemini 설정. 출력 상한·타임아웃 같은 공통 항목은 {@link ReportProperties}에 있다.
 *
 * @param apiKey         절대 커밋하지 않는다. 환경변수 GEMINI_API_KEY로만 주입한다
 * @param model          모델 이름. 버전을 박으면 썩는다.
 *                       (gemini-2.0-flash는 사라졌고 gemini-2.5-flash는 신규 키로 404가 난다)
 * @param thinkingBudget 추론 모델의 생각 토큰 예산. 0이면 끔.
 *                       켜 두면 생각 토큰이 출력 상한을 같이 깎아먹어 본문이 잘린다
 */
@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(String apiKey, String model, int thinkingBudget) {
}
