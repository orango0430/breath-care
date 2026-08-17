package org.exaple.breath_care.report.generate;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

/**
 * OpenAI Chat Completions API의 요청·응답 모양. 필요한 필드만 옮겨 담았다.
 *
 * <p>SDK를 안 쓴 이유는 Gemini 쪽과 같다. 엔드포인트 하나 때문에 전이 의존성을 늘릴 이유가 없고,
 * Spring이 가진 RestClient로 충분하다.
 */
final class OpenAiApi {

    private OpenAiApi() {
    }

    /**
     * <p><b>temperature를 보내지 않는다.</b> 추론 계열 모델은 기본값 외의 temperature를 거부해서,
     * 모델을 갈아탈 때마다 400이 나는 원인이 된다. 이 작업은 숫자를 문장으로 옮기는 일이라
     * 굳이 조절할 이유도 없다.
     *
     * <p>{@code maxCompletionTokens}는 예전 {@code max_tokens}를 대체한 이름이다.
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    record ChatRequest(
            String model,
            List<Message> messages,
            @JsonProperty("max_completion_tokens") int maxCompletionTokens,
            @JsonProperty("response_format") ResponseFormat responseFormat
    ) {
    }

    /**
     * @param refusal 안전 정책에 걸리면 content 대신 여기에 이유가 온다. 보낼 때는 비운다
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonIgnoreProperties(ignoreUnknown = true)
    record Message(String role, String content, String refusal) {

        static Message system(String content) {
            return new Message("system", content, null);
        }

        static Message user(String content) {
            return new Message("user", content, null);
        }
    }

    /** 구조를 못 박아 두면 필드가 빠지거나 이름이 달라지는 일이 없다. */
    record ResponseFormat(String type, @JsonProperty("json_schema") JsonSchema jsonSchema) {

        static ResponseFormat jsonSchema(JsonSchema schema) {
            return new ResponseFormat("json_schema", schema);
        }
    }

    /**
     * @param strict true면 스키마를 벗어난 응답이 아예 생성되지 않는다.
     *               단 모든 객체에 additionalProperties=false와 전 필드 required가 필요하다
     */
    record JsonSchema(String name, boolean strict, Map<String, Object> schema) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record ChatResponse(List<Choice> choices, Usage usage) {

        /** 응답 어디가 비어 있어도 터지지 않게 한 번에 훑는다. 못 찾으면 null. */
        String firstContent() {
            if (choices == null || choices.isEmpty()) {
                return null;
            }
            Message message = choices.get(0).message();
            return (message == null) ? null : message.content();
        }

        /** 안전 정책에 걸리면 content 대신 이 값이 채워져 온다. */
        String firstRefusal() {
            if (choices == null || choices.isEmpty()) {
                return null;
            }
            Message message = choices.get(0).message();
            return (message == null) ? null : message.refusal();
        }

        String finishReason() {
            return (choices == null || choices.isEmpty()) ? null : choices.get(0).finishReason();
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Choice(
            Message message,
            @JsonProperty("finish_reason") String finishReason
    ) {
    }

    /** 실제로 쓴 토큰. 공유 키라 우리가 얼마나 쓰는지 남겨 두는 게 특히 중요하다. */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record Usage(
            @JsonProperty("prompt_tokens") Integer promptTokens,
            @JsonProperty("completion_tokens") Integer completionTokens,
            @JsonProperty("total_tokens") Integer totalTokens,
            @JsonProperty("completion_tokens_details") CompletionDetails completionDetails
    ) {
        /** 추론에 쓴 토큰. 못 찾으면 null. */
        Integer reasoningTokens() {
            return (completionDetails == null) ? null : completionDetails.reasoningTokens();
        }
    }

    /**
     * gpt-5 계열은 추론 모델이라 답하기 전에 "생각"을 할 수 있고,
     * <b>그 토큰이 completion_tokens에 포함돼 max_completion_tokens를 같이 깎아먹는다.</b>
     * 본문이 상한에서 잘리기 시작하면 여기부터 확인해야 한다.
     * (gpt-5.4-mini는 이 작업에서 0이지만, 모델을 갈아타면 달라질 수 있다)
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record CompletionDetails(@JsonProperty("reasoning_tokens") Integer reasoningTokens) {
    }
}
