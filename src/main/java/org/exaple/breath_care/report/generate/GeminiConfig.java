package org.exaple.breath_care.report.generate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/**
 * gemini.enabled=true 일 때만 뜬다. FirebaseConfig와 같은 방식이다.
 */
@Configuration
@ConditionalOnProperty(name = "gemini.enabled", havingValue = "true")
public class GeminiConfig {

    private static final Logger log = LoggerFactory.getLogger(GeminiConfig.class);

    private static final String BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);

    @Bean
    public RestClient geminiRestClient(GeminiProperties properties) {
        if (properties.apiKey() == null || properties.apiKey().isBlank()) {
            // 켜 놓고 키를 안 넣으면 요청이 들어온 뒤에야 401로 알게 된다. 뜰 때 바로 알려주는 편이 낫다.
            throw new IllegalStateException(
                    "gemini.enabled=true 인데 gemini.api-key가 비어 있습니다. 환경변수 GEMINI_API_KEY를 설정하세요.");
        }

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(CONNECT_TIMEOUT);
        factory.setReadTimeout(Duration.ofSeconds(properties.timeoutSeconds()));

        log.info("Gemini 리포트 생성 활성화 (model={})", properties.model());

        return RestClient.builder()
                .baseUrl(BASE_URL)
                .requestFactory(factory)
                // 키를 URL 쿼리로 붙이면 접근 로그에 그대로 남는다. 헤더로 보낸다.
                .defaultHeader("x-goog-api-key", properties.apiKey())
                .build();
    }
}
