package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;

/**
 * OpenAI로 리포트 본문을 만든다. 프롬프트는 Gemini와 같은 {@link ReportPrompt}를 쓴다.
 *
 * <p>제공자를 갈아탄다고 문구 규칙까지 갈라지면 두 벌을 따로 손봐야 한다.
 * 지표 방향(HRV는 높을수록 좋음) 같은 건 한 군데서만 관리해야 안전하다.
 */
@Component
@ConditionalOnProperty(name = ReportProvider.KEY, havingValue = ReportProvider.OPENAI)
public class OpenAiReportGenerator implements ReportGenerator {

    private static final Logger log = LoggerFactory.getLogger(OpenAiReportGenerator.class);

    private static final String SCHEMA_NAME = "weekly_report";

    private final RestClient openAiRestClient;
    private final ObjectMapper objectMapper;
    private final OpenAiProperties openAiProperties;
    private final ReportProperties reportProperties;

    public OpenAiReportGenerator(@Qualifier("openAiRestClient") RestClient openAiRestClient,
                                 ObjectMapper objectMapper,
                                 OpenAiProperties openAiProperties,
                                 ReportProperties reportProperties) {
        this.openAiRestClient = openAiRestClient;
        this.objectMapper = objectMapper;
        this.openAiProperties = openAiProperties;
        this.reportProperties = reportProperties;
    }

    @Override
    public ReportContent generate(ReportInput input) {
        OpenAiApi.ChatResponse response = call(buildRequest(input));
        logUsage(response.usage());

        String refusal = response.firstRefusal();
        if (refusal != null && !refusal.isBlank()) {
            log.warn("OpenAI가 생성을 거부했습니다: {}", refusal);
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }

        String json = response.firstContent();
        if (json == null || json.isBlank()) {
            log.warn("OpenAI 응답이 비어 있습니다. finishReason={}", response.finishReason());
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }

        return parse(json);
    }

    @Override
    public String modelName() {
        return openAiProperties.model();
    }

    private OpenAiApi.ChatRequest buildRequest(ReportInput input) {
        return new OpenAiApi.ChatRequest(
                openAiProperties.model(),
                List.of(OpenAiApi.Message.system(ReportPrompt.SYSTEM_INSTRUCTION),
                        OpenAiApi.Message.user(ReportPrompt.userContent(input))),
                reportProperties.maxOutputTokens(),
                OpenAiApi.ResponseFormat.jsonSchema(
                        new OpenAiApi.JsonSchema(SCHEMA_NAME, true, responseSchema())));
    }

    /**
     * strict 모드는 모든 객체에 additionalProperties=false와 전 필드 required를 요구한다.
     * 하나라도 빠지면 400이 나므로 함께 둔다.
     */
    private Map<String, Object> responseSchema() {
        return Map.of(
                "type", "object",
                "properties", Map.of(
                        "summary", Map.of("type", "string"),
                        "insights", Map.of("type", "array", "items", Map.of("type", "string")),
                        "advice", Map.of("type", "array", "items", Map.of("type", "string"))),
                "required", List.of("summary", "insights", "advice"),
                "additionalProperties", false);
    }

    private OpenAiApi.ChatResponse call(OpenAiApi.ChatRequest request) {
        try {
            OpenAiApi.ChatResponse response = openAiRestClient.post()
                    .uri("/chat/completions")
                    .body(request)
                    .retrieve()
                    .body(OpenAiApi.ChatResponse.class);

            if (response == null) {
                throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
            }
            return response;

        } catch (RestClientException e) {
            // 공유 키라 다른 팀 트래픽 때문에 429가 날 수 있다. 크레딧 소진도 마찬가지다.
            // 사용자가 할 수 있는 일은 어느 쪽이든 같으므로 밖으로는 한 가지로 내보낸다.
            log.warn("OpenAI 호출 실패", e);
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }
    }

    private ReportContent parse(String json) {
        try {
            return objectMapper.readValue(json, ReportContent.class);
        } catch (JacksonException e) {
            log.warn("OpenAI 응답 파싱 실패: {}", json, e);
            throw new BusinessException(ErrorCode.REPORT_UNAVAILABLE);
        }
    }

    /** 공유 키라 우리가 얼마나 쓰는지 남겨 두는 게 특히 중요하다. */
    private void logUsage(OpenAiApi.Usage usage) {
        if (usage == null) {
            return;
        }
        log.info("OpenAI usage: prompt={} completion={} total={}",
                usage.promptTokens(), usage.completionTokens(), usage.totalTokens());
    }
}
