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
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record GenerationConfig(
            double temperature,
            int maxOutputTokens,
            String responseMimeType,
            Schema responseSchema
    ) {
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
    record GenerateResponse(List<Candidate> candidates) {

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
}
