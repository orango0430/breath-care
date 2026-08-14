package org.exaple.breath_care.measurement;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 비회원 측정. 로그인 없이 계산만 받아 가고 서버에는 아무것도 남기지 않는다.
 * 신호처리가 스텁이라 심박수는 항상 72로 고정된다. 점수는 과거 심박수로만 움직인다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class GuestMeasurementControllerTest {

    private static final String ANALYZE = "/api/measurements/analyze";

    @Autowired
    MockMvc mockMvc;
    @Autowired
    MeasurementRepository measurementRepository;
    @Autowired
    MeasurementSignalRepository signalRepository;

    /** fps 30으로 frameCount 개의 파형을 만든다. recentHrs는 JSON 조각으로 그대로 끼운다. */
    private String requestBody(int durationSec, int frameCount, String recentHrs) {
        String samples = IntStream.range(0, frameCount)
                .mapToObj(i -> String.valueOf(120.0 + (i % 10) * 0.5))
                .collect(Collectors.joining(","));

        return """
                {"samples":[%s],"fps":30,"durationSec":%d,"recentHrs":%s}
                """.formatted(samples, durationSec, recentHrs);
    }

    @Test
    @DisplayName("토큰 없이도 측정 결과를 받는다")
    void worksWithoutToken() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, "[]")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.hr").value(72.0))
                .andExpect(jsonPath("$.data.hrv").value(35.0))
                .andExpect(jsonPath("$.data.quality").value("GOOD"))
                .andExpect(jsonPath("$.data.measuredAt").isNotEmpty())
                // 저장하지 않았으니 가리킬 id가 없다
                .andExpect(jsonPath("$.data.id").doesNotExist());
    }

    @Test
    @DisplayName("비회원 측정은 서버에 저장되지 않는다")
    void storesNothing() throws Exception {
        long measurementsBefore = measurementRepository.count();
        long signalsBefore = signalRepository.count();

        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, "[70.0,71.0,69.0,72.0,70.0]")))
                .andExpect(status().isOk());

        assertThat(measurementRepository.count()).isEqualTo(measurementsBefore);
        assertThat(signalRepository.count()).isEqualTo(signalsBefore);
    }

    @Test
    @DisplayName("과거 심박수가 5개 미만이면 점수를 내지 않고 남은 횟수를 알려준다")
    void withoutEnoughHistory() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, "[70.0,71.0,69.0,72.0]")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.stressScore").doesNotExist())
                .andExpect(jsonPath("$.data.baseline.ready").value(false))
                .andExpect(jsonPath("$.data.baseline.sampleCount").value(4))
                .andExpect(jsonPath("$.data.baseline.remainingSamples").value(1));
    }

    @Test
    @DisplayName("과거 심박수를 아예 안 보내도 400이 아니라 점수만 비워서 준다")
    void recentHrsIsOptional() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"samples":[%s],"fps":30,"durationSec":60}
                                """.formatted(IntStream.range(0, 1800)
                                .mapToObj(i -> "120.0").collect(Collectors.joining(",")))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.hr").value(72.0))
                .andExpect(jsonPath("$.data.stressScore").doesNotExist())
                .andExpect(jsonPath("$.data.baseline.ready").value(false));
    }

    /**
     * 점수를 숫자로 꺼낸다. JSONPath 매처는 크기에 따라 Double과 BigDecimal을 오가서
     * 부등호 비교에 그대로 쓸 수 없다.
     */
    private double stressScoreOf(String recentHrs) throws Exception {
        String body = mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, recentHrs)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.baseline.ready").value(true))
                .andReturn().getResponse().getContentAsString();

        Matcher matcher = Pattern.compile("\"stressScore\":([0-9.eE+-]+)").matcher(body);
        assertThat(matcher.find()).as("응답에 stressScore가 있어야 한다").isTrue();

        return Double.parseDouble(matcher.group(1));
    }

    @Test
    @DisplayName("평소보다 심박수가 높으면 점수가 높게 나온다")
    void higherThanUsualScoresHigh() throws Exception {
        // 평소 60대인 사람의 72 → 기준선보다 한참 위
        assertThat(stressScoreOf("[58.0,60.0,62.0,59.0,61.0]")).isGreaterThan(90.0);
    }

    @Test
    @DisplayName("평소보다 심박수가 낮으면 점수가 낮게 나온다")
    void lowerThanUsualScoresLow() throws Exception {
        // 평소 80대인 사람의 72 → 기준선보다 아래
        assertThat(stressScoreOf("[84.0,86.0,85.0,87.0,83.0]")).isLessThan(10.0);
    }

    @Test
    @DisplayName("회원과 같은 품질 기준을 적용한다 — 프레임이 모자라면 422")
    void rejectsDroppedFrames() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 500, "[]")))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("말이 안 되는 심박수가 섞이면 400 — 기준선이 통째로 망가진다")
    void rejectsAbsurdHeartRate() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, "[70.0,71.0,69.0,72.0,500.0]")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("인증 없이 열린 건 이 경로의 POST뿐이다")
    void onlyAnalyzeIsOpen() throws Exception {
        // 같은 prefix의 저장용 엔드포인트는 여전히 토큰을 요구한다
        mockMvc.perform(post("/api/measurements")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800, "[]")))
                .andExpect(status().isUnauthorized());
    }
}
