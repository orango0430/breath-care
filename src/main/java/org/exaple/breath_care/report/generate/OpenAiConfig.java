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
 * report.provider=openai 일 때만 뜬다.
 */
@Configuration
@ConditionalOnProperty(name = ReportProvider.KEY, havingValue = ReportProvider.OPENAI)
public class OpenAiConfig {

    private static final Logger log = LoggerFactory.getLogger(OpenAiConfig.class);

    private static final String BASE_URL = "https://api.openai.com/v1";
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);

    @Bean
    public RestClient openAiRestClient(OpenAiProperties properties, ReportProperties reportProperties) {
        if (properties.apiKey() == null || properties.apiKey().isBlank()) {
            // 켜 놓고 키를 안 넣으면 요청이 들어온 뒤에야 401로 알게 된다. 뜰 때 바로 알려주는 편이 낫다.
            throw new IllegalStateException(
                    "report.provider=openai 인데 openai.api-key가 비어 있습니다. 환경변수 OPENAI_API_KEY를 설정하세요.");
        }

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(CONNECT_TIMEOUT);
        factory.setReadTimeout(Duration.ofSeconds(reportProperties.timeoutSeconds()));

        log.info("OpenAI 리포트 생성 활성화 (model={})", properties.model());

        return RestClient.builder()
                .baseUrl(BASE_URL)
                .requestFactory(factory)
                .defaultHeader("Authorization", "Bearer " + properties.apiKey())
                .build();
    }
}
