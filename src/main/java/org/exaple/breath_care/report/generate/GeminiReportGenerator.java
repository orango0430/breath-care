package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.util.List;

/**
 * Gemini로 리포트 본문을 만든다.
 *
 * <p>온도를 낮게 둔 이유는 같은 주 데이터로 두 번 만들었을 때 말이 크게 달라지면
 * 사용자가 어느 쪽을 믿어야 할지 모르게 되기 때문이다.
 */
@Component
@ConditionalOnProperty(name = "gemini.enabled", havingValue = "true")
public class GeminiReportGenerator implements ReportGenerator {

    private static final Logger log = LoggerFactory.getLogger(GeminiReportGenerator.class);

    private static final double TEMPERATURE = 0.4;
    private static final String JSON_MIME = "application/json";

    private final RestClient geminiRestClient;
    private final ObjectMapper objectMapper;
    private final GeminiProperties properties;

    public GeminiReportGenerator(RestClient geminiRestClient, ObjectMapper objectMapper,
                                 GeminiProperties properties) {
        this.geminiRestClient = geminiRestClient;
        this.objectMapper = objectMapper;
        this.properties = properties;
    }

    @Override
    public ReportContent generate(ReportInput input) {
        GeminiApi.GenerateResponse response = call(buildRequest(input));
        logUsage(response.usageMetadata());

        String json = response.firstText();
        if (json == null || json.isBlank()) {
            // 안전 필터에 걸리거나 토큰 상한에서 잘리면 본문이 비어 온다.
            log.warn("Gemini 응답이 비어 있습니다. finishReason={}", response.finishReason());
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }

        return parse(json);
    }

    @Override
    public String modelName() {
        return properties.model();
    }

    private GeminiApi.GenerateRequest buildRequest(ReportInput input) {
        return new GeminiApi.GenerateRequest(
                List.of(GeminiApi.Content.of(ReportPrompt.userContent(input))),
                GeminiApi.Content.of(ReportPrompt.SYSTEM_INSTRUCTION),
                new GeminiApi.GenerationConfig(
                        TEMPERATURE,
                        properties.maxOutputTokens(),
                        JSON_MIME,
                        ReportPrompt.responseSchema(),
                        new GeminiApi.ThinkingConfig(properties.thinkingBudget())));
    }

    private GeminiApi.GenerateResponse call(GeminiApi.GenerateRequest request) {
        try {
            GeminiApi.GenerateResponse response = geminiRestClient.post()
                    .uri("/models/{model}:generateContent", properties.model())
                    .body(request)
                    .retrieve()
                    .body(GeminiApi.GenerateResponse.class);

            if (response == null) {
                throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
            }
            return response;

        } catch (RestClientException e) {
            // 한도 초과(429)든 키 오류(401)든 사용자가 할 수 있는 일은 같다. 밖으로는 한 가지로 내보낸다.
            log.warn("Gemini 호출 실패", e);
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }
    }

    /**
     * 리포트 한 건에 든 토큰을 남긴다. 캐시가 실제로 호출을 막고 있는지는
     * 이 줄이 얼마나 드물게 찍히는지로 확인한다.
     */
    private void logUsage(GeminiApi.UsageMetadata usage) {
        if (usage == null) {
            return;
        }
        log.info("Gemini usage: prompt={} output={} thoughts={} total={}",
                usage.promptTokenCount(), usage.candidatesTokenCount(),
                usage.thoughtsTokenCount(), usage.totalTokenCount());
    }

    private ReportContent parse(String json) {
        try {
            return objectMapper.readValue(json, ReportContent.class);
        } catch (JacksonException e) {
            // 스키마를 못 박아 뒀으니 거의 없지만, 토큰 상한에서 잘리면 JSON이 미완성으로 온다.
            log.warn("Gemini 응답 파싱 실패: {}", json, e);
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }
    }
}
