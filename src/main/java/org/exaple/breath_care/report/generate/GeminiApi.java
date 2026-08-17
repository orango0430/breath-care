package org.exaple.breath_care.report.generate;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

/**
 * Gemini generateContent API의 요청·응답 모양. 필요한 필드만 옮겨 담았다.
 *
 * <p>SDK를 쓰지 않고 직접 만든 이유: 이 프로젝트가 Gemini에 요구하는 건 엔드포인트 하나뿐인데,
 * SDK를 붙이면 전이 의존성이 수십 개 딸려 온다. Spring이 이미 가진 RestClient로 충분하다.
 */
final class GeminiApi {

    private GeminiApi() {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    record GenerateRequest(
            List<Content> contents,
            Content systemInstruction,
            GenerationConfig generationConfig
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Content(List<Part> parts) {

        static Content of(String text) {
            return new Content(List.of(new Part(text)));
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Part(String text) {
    }

    /**
     * @param responseMimeType application/json으로 두면 모델이 산문 대신 JSON만 낸다.
     *                         "```json" 같은 군더더기를 벗겨낼 필요가 없어진다
     * @param responseSchema   구조를 못 박아 두면 필드가 빠지거나 이름이 달라지는 일이 없다
     * @param thinkingConfig   추론 모델의 생각 토큰 조절
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record GenerationConfig(
            double temperature,
            int maxOutputTokens,
            String responseMimeType,
            Schema responseSchema,
            ThinkingConfig thinkingConfig
    ) {
    }

    /**
     * 요즘 flash 모델은 추론 모델이라 답하기 전에 "생각"을 하고,
     * <b>그 생각 토큰이 maxOutputTokens를 같이 깎아먹는다.</b>
     * 껐을 때와 안 껐을 때 같은 프롬프트에서 생각에만 수십~수백 토큰이 더 든다.
     *
     * <p>이 작업은 집계된 숫자를 문장으로 옮기는 일이라 추론이 필요 없다.
     * 꺼 두면 비용도 줄고 본문이 상한에서 잘릴 위험도 사라진다.
     *
     * @param thinkingBudget 0이면 끔. -1은 모델이 알아서 정함
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record ThinkingConfig(int thinkingBudget) {
    }

    /** OpenAPI 스키마의 아주 일부만 쓴다. 배열이면 items, 객체면 properties가 채워진다. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record Schema(String type, Map<String, Schema> properties, Schema items, List<String> required) {

        static Schema string() {
            return new Schema("STRING", null, null, null);
        }

        static Schema arrayOfString() {
            return new Schema("ARRAY", null, string(), null);
        }

        static Schema object(Map<String, Schema> properties, List<String> required) {
            return new Schema("OBJECT", properties, null, required);
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record GenerateResponse(List<Candidate> candidates, UsageMetadata usageMetadata) {

        /** 응답 어디가 비어 있어도 터지지 않게 한 번에 훑는다. 못 찾으면 null. */
        String firstText() {
            if (candidates == null || candidates.isEmpty()) {
                return null;
            }
            Content content = candidates.get(0).content();
            if (content == null || content.parts() == null || content.parts().isEmpty()) {
                return null;
            }
            return content.parts().get(0).text();
        }

        String finishReason() {
            return (candidates == null || candidates.isEmpty()) ? null : candidates.get(0).finishReason();
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Candidate(Content content, String finishReason) {
    }

    /**
     * 실제로 쓴 토큰. 남겨 두지 않으면 사용량을 아꼈는지 확인할 방법이 없다.
     *
     * @param thoughtsTokenCount 생각 토큰. 0이 아니면 thinkingConfig가 안 먹은 것이다
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record UsageMetadata(
            Integer promptTokenCount,
            Integer candidatesTokenCount,
            Integer thoughtsTokenCount,
            Integer totalTokenCount
    ) {
    }
}
