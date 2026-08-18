package org.exaple.breath_care.report.generate;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * OpenAI 설정. 출력 상한·타임아웃 같은 공통 항목은 {@link ReportProperties}에 있다.
 *
 * @param apiKey 절대 커밋하지 않는다. 환경변수 OPENAI_API_KEY로만 주입한다.
 *               <b>동아리 조직 계정 키라 다른 팀과 공유한다.</b> 속도 제한과 크레딧이
 *               조직 단위로 묶이므로, 우리 쪽 호출은 캐시·쿨다운으로 최소한만 나간다
 * @param model  모델 이름. 코드가 아니라 설정이라 갈아탈 때 재배포만 하면 된다
 */
@ConfigurationProperties(prefix = "openai")
public record OpenAiProperties(String apiKey, String model) {
}
