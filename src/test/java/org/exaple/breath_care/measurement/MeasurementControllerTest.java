package org.exaple.breath_care.measurement;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class MeasurementControllerTest {

    private static final String MEASUREMENTS = "/api/measurements";

    @Autowired
    MockMvc mockMvc;
    @Autowired
    MeasurementSignalRepository signalRepository;
    @Autowired
    MeasurementRepository measurementRepository;

    private String token;
    private Long userId;

    @BeforeEach
    void login() throws Exception {
        String signup = mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"m@test.com","password":"password123","nickname":"m"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        int idStart = signup.indexOf("\"id\":") + "\"id\":".length();
        int idEnd = idStart;
        while (Character.isDigit(signup.charAt(idEnd))) {
            idEnd++;
        }
        userId = Long.parseLong(signup.substring(idStart, idEnd));

        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"m@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        token = body.substring(start, body.indexOf('"', start));
    }

    /** fps 30으로 durationSec 초만큼의 파형을 만든다. */
    private String requestBody(int durationSec, int frameCount) {
        String samples = IntStream.range(0, frameCount)
                .mapToObj(i -> String.valueOf(120.0 + (i % 10) * 0.5))
                .collect(Collectors.joining(","));

        return """
                {"samples":[%s],"fps":30,"durationSec":%d}
                """.formatted(samples, durationSec);
    }

    @Test
    @DisplayName("측정 결과를 보내면 심박수·HRV·품질을 돌려준다")
    void measure() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").isNumber())
                .andExpect(jsonPath("$.data.hr").isNumber())
                .andExpect(jsonPath("$.data.hrv").isNumber())
                .andExpect(jsonPath("$.data.quality").value("GOOD"))
                .andExpect(jsonPath("$.data.measuredAt").isNotEmpty())
                // baseline이 아직 없으므로 스트레스 지수는 비어 있다
                .andExpect(jsonPath("$.data.stressScore").doesNotExist());
    }

    @Test
    @DisplayName("원시 파형을 함께 저장한다 (나중에 알고리즘 재검증에 쓴다)")
    void storesRawSignal() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isCreated());

        assertThat(signalRepository.findAll()).hasSize(1);
        MeasurementSignal signal = signalRepository.findAll().get(0);
        assertThat(signal.getFps()).isEqualTo(30);
        assertThat(signal.getDurationSec()).isEqualTo(60);
        assertThat(signal.getSamples().split(",")).hasSize(1800);
    }

    @Test
    @DisplayName("프레임이 많이 누락되면 422로 재측정을 요구한다")
    void rejectsDroppedFrames() throws Exception {
        // 60초 × 30fps = 1800 기대인데 500개만 도착
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 500)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("측정이 너무 짧으면 422")
    void rejectsTooShortMeasurement() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(15, 450)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("신호가 비어 있으면 400")
    void rejectsEmptySamples() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"samples":[],"fps":30,"durationSec":60}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("fps가 범위를 벗어나면 400")
    void rejectsInvalidFps() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"samples":[1.0,2.0],"fps":5,"durationSec":60}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("토큰 없이 측정을 보내면 401")
    void requiresAuth() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("측정 이력을 최신순으로 조회한다")
    void findHistory() throws Exception {
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody(60, 1800)));
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody(60, 1800)));

        mockMvc.perform(get(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    /** 기준선을 채우기 위한 과거 측정. API로 만들면 매번 1800개 샘플을 보내야 해 느리다. */
    private void seedMeasurements(int count, double hr) {
        for (int i = 0; i < count; i++) {
            measurementRepository.save(Measurement.create(
                    userId, hr, 35.0, null, MeasurementQuality.GOOD, java.time.Instant.now()));
        }
    }

    @Test
    @DisplayName("측정이 5회 미만이면 기준선이 준비되지 않는다")
    void baselineNotReady() throws Exception {
        seedMeasurements(3, 70.0);

        mockMvc.perform(get(MEASUREMENTS + "/baseline").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.ready").value(false))
                .andExpect(jsonPath("$.data.sampleCount").value(3))
                .andExpect(jsonPath("$.data.remainingSamples").value(2))
                .andExpect(jsonPath("$.data.baselineHr").doesNotExist());
    }

    @Test
    @DisplayName("측정이 5회 이상이면 기준선이 완성된다")
    void baselineReady() throws Exception {
        seedMeasurements(5, 70.0);

        mockMvc.perform(get(MEASUREMENTS + "/baseline").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.ready").value(true))
                .andExpect(jsonPath("$.data.sampleCount").value(5))
                .andExpect(jsonPath("$.data.baselineHr").value(70.0));
    }

    @Test
    @DisplayName("기준선이 없으면 스트레스 지수가 비어 있다")
    void noStressScoreWithoutBaseline() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.stressScore").doesNotExist());
    }

    @Test
    @DisplayName("기준선이 쌓이면 스트레스 지수가 산출된다")
    void stressScoreAfterBaseline() throws Exception {
        // 평소 심박이 60인 사용자. 스텁이 돌려주는 72는 평소보다 한참 높다.
        seedMeasurements(5, 60.0);

        String body = mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.stressScore").isNumber())
                .andReturn().getResponse().getContentAsString();

        // 기준선(60)보다 4 표준편차(하한 3.0) 위라 높은 점수가 나온다
        java.util.regex.Matcher matcher =
                java.util.regex.Pattern.compile("\"stressScore\":([0-9.]+)").matcher(body);
        assertThat(matcher.find()).isTrue();
        assertThat(Double.parseDouble(matcher.group(1))).isGreaterThan(80.0);
    }

    @Test
    @DisplayName("기준선은 내 측정만으로 만든다")
    void baselineIsScopedToUser() throws Exception {
        seedMeasurements(5, 70.0);

        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"base-other@test.com","password":"password123","nickname":"o"}
                        """));
        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"base-other@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        String otherToken = body.substring(start, body.indexOf('"', start));

        mockMvc.perform(get(MEASUREMENTS + "/baseline").header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
                .andExpect(jsonPath("$.data.ready").value(false))
                .andExpect(jsonPath("$.data.sampleCount").value(0));
    }

    @Test
    @DisplayName("남의 측정은 이력에 섞이지 않는다")
    void historyIsScopedToUser() throws Exception {
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody(60, 1800)));

        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"other-m@test.com","password":"password123","nickname":"o"}
                        """));
        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"other-m@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        String otherToken = body.substring(start, body.indexOf('"', start));

        mockMvc.perform(get(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }
}
