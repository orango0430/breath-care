package org.exaple.breath_care.report.generate;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.statistics.dto.DailyMetric;
import org.exaple.breath_care.statistics.dto.MetricSummary;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/**
 * Gemini 호출부. 실제 API를 부르지 않고 요청 모양과 응답 처리만 확인한다.
 *
 * <p>특히 <b>실패가 전부 REPORT_UNAVAILABLE로 모이는지</b>를 본다.
 * 여기서 예외가 새어 나가면 리포트 하나 때문에 500이 뜬다.
 */
class GeminiReportGeneratorTest {

    private static final String BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
    private static final String MODEL = "gemini-flash-latest";

    private final ObjectMapper mapper = JsonMapper.builder().build();

    private MockRestServiceServer server;
    private GeminiReportGenerator generator;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();

        generator = new GeminiReportGenerator(
                builder.build(),
                mapper,
                new GeminiProperties(true, "test-key", MODEL, 3, 6, 900, 0, 20));
    }

    private ReportInput input() {
        return new ReportInput(
                LocalDate.of(2026, 8, 11),
                LocalDate.of(2026, 8, 17),
                12,
                MetricSummary.of(List.of(72.0, 80.0)),
                MetricSummary.of(List.of(35.0, 41.0)),
                MetricSummary.of(List.of(40.0, 55.0)),
                List.of(new DailyMetric(LocalDate.of(2026, 8, 11), 72.0, 35.0, 40.0, 2),
                        DailyMetric.empty(LocalDate.of(2026, 8, 12))));
    }

    /** Gemini는 본문 JSON을 문자열 한 칸(text)에 담아 돌려준다. */
    private String responseWith(String innerJson) {
        return mapper.writeValueAsString(Map.of(
                "candidates", List.of(Map.of(
                        "content", Map.of("parts", List.of(Map.of("text", innerJson))),
                        "finishReason", "STOP"))));
    }

    @Test
    @DisplayName("응답 JSON을 리포트 본문으로 읽는다")
    void parsesResponse() {
        String inner = """
                {"summary":"이번 주는 안정적이었어요.",
                 "insights":["수요일에 심박수가 높았어요","주말에 HRV가 올라갔어요"],
                 "advice":["발표 전 4-7-8 호흡"]}
                """;
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andExpect(method(org.springframework.http.HttpMethod.POST))
                .andRespond(withSuccess(responseWith(inner), MediaType.APPLICATION_JSON));

        ReportContent content = generator.generate(input());

        assertThat(content.summary()).isEqualTo("이번 주는 안정적이었어요.");
        assertThat(content.insights()).hasSize(2);
        assertThat(content.advice()).containsExactly("발표 전 4-7-8 호흡");
        server.verify();
    }

    @Test
    @DisplayName("요청에 출력 상한과 응답 스키마를 함께 실어 보낸다")
    void sendsGenerationConfig() {
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andExpect(jsonPath("$.generationConfig.maxOutputTokens").value(900))
                .andExpect(jsonPath("$.generationConfig.responseMimeType").value("application/json"))
                // 스키마를 못 박아야 필드 이름이 흔들리지 않는다
                .andExpect(jsonPath("$.generationConfig.responseSchema.required").isArray())
                .andExpect(jsonPath("$.generationConfig.responseSchema.properties.insights.type").value("ARRAY"))
                // 생각 토큰이 켜져 있으면 출력 상한을 같이 깎아먹어 본문이 잘린다
                .andExpect(jsonPath("$.generationConfig.thinkingConfig.thinkingBudget").value(0))
                // HRV 방향을 알려주는 시스템 지시가 빠지면 리포트가 거꾸로 해석한다
                .andExpect(jsonPath("$.systemInstruction.parts[0].text").exists())
                .andRespond(withSuccess(
                        responseWith("{\"summary\":\"s\",\"insights\":[],\"advice\":[]}"),
                        MediaType.APPLICATION_JSON));

        generator.generate(input());
        server.verify();
    }

    @Test
    @DisplayName("한도 초과(429)는 REPORT_UNAVAILABLE로 바뀐다")
    void quotaExceeded() {
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andRespond(withStatus(HttpStatus.TOO_MANY_REQUESTS));

        assertThatThrownBy(() -> generator.generate(input()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.REPORT_UNAVAILABLE);
    }

    @Test
    @DisplayName("서버 오류도 REPORT_UNAVAILABLE로 바뀐다")
    void serverError() {
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andRespond(withServerError());

        assertThatThrownBy(() -> generator.generate(input()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.REPORT_UNAVAILABLE);
    }

    @Test
    @DisplayName("본문이 비어 오면 REPORT_UNAVAILABLE로 바뀐다")
    void emptyCandidates() {
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andRespond(withSuccess("{\"candidates\":[]}", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> generator.generate(input()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.REPORT_UNAVAILABLE);
    }

    @Test
    @DisplayName("토큰 상한에서 잘린 JSON도 500으로 새지 않는다")
    void truncatedJson() {
        server.expect(requestTo(BASE_URL + "/models/" + MODEL + ":generateContent"))
                .andRespond(withSuccess(
                        responseWith("{\"summary\":\"잘린 문장"), MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> generator.generate(input()))
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(ErrorCode.REPORT_UNAVAILABLE);
    }
}
