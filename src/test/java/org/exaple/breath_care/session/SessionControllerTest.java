package org.exaple.breath_care.session;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementQuality;
import org.exaple.breath_care.measurement.MeasurementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class SessionControllerTest {

    private static final String SESSIONS = "/api/sessions";

    @Autowired
    MockMvc mockMvc;
    @Autowired
    MeasurementRepository measurementRepository;

    private String token;
    private Long userId;

    @BeforeEach
    void login() throws Exception {
        String signup = mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"s@test.com","password":"password123","nickname":"s"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        userId = extractLong(signup, "\"id\":");

        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"s@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = login.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        token = login.substring(start, login.indexOf('"', start));
    }

    private long extractLong(String body, String key) {
        int start = body.indexOf(key) + key.length();
        int end = start;
        while (end < body.length() && Character.isDigit(body.charAt(end))) {
            end++;
        }
        return Long.parseLong(body.substring(start, end));
    }

    /** 측정을 직접 만든다. 신호처리가 스텁이라 API로는 고정값밖에 못 만들기 때문. */
    private Long measurement(double hr, Double hrv, Double stressScore) {
        return measurementRepository.save(Measurement.create(
                userId, hr, hrv, stressScore, MeasurementQuality.GOOD, Instant.now())).getId();
    }

    private Long startSession(Long preId) throws Exception {
        String body = mockMvc.perform(post(SESSIONS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"preMeasurementId":%d,"preset":"EXHALE_EXTENDED"}
                                """.formatted(preId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return extractLong(body, "\"id\":");
    }

    @Test
    @DisplayName("세션을 시작하면 전 측정만 담기고 변화량은 비어 있다")
    void start() throws Exception {
        Long preId = measurement(88, 24.0, 78.0);

        mockMvc.perform(post(SESSIONS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"preMeasurementId":%d,"preset":"EXHALE_EXTENDED"}
                                """.formatted(preId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.preset").value("EXHALE_EXTENDED"))
                .andExpect(jsonPath("$.data.before.hr").value(88.0))
                .andExpect(jsonPath("$.data.before.stressScore").value(78.0))
                .andExpect(jsonPath("$.data.after").doesNotExist())
                .andExpect(jsonPath("$.data.change").doesNotExist())
                .andExpect(jsonPath("$.data.endedAt").doesNotExist());
    }

    @Test
    @DisplayName("세션을 끝내면 세 지표의 전후 변화를 계산한다")
    void complete() throws Exception {
        Long preId = measurement(88, 24.0, 78.0);
        Long sessionId = startSession(preId);
        Long postId = measurement(74, 29.0, 62.0);

        mockMvc.perform(patch(SESSIONS + "/" + sessionId + "/complete")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"postMeasurementId":%d}
                                """.formatted(postId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.after.hr").value(74.0))
                // 88 → 74 = -14 (약 -15.9%)
                .andExpect(jsonPath("$.data.change.hr").value(-14.0))
                // JSON 숫자는 BigDecimal로 파싱되므로 matcher도 BigDecimal로 맞춘다
                .andExpect(jsonPath("$.data.change.hrPercent")
                        .value(org.hamcrest.Matchers.closeTo(new java.math.BigDecimal("-15.909"),
                                new java.math.BigDecimal("0.01"))))
                // HRV는 늘어나는 것이 좋아진 것
                .andExpect(jsonPath("$.data.change.hrv").value(5.0))
                // 스트레스는 줄어드는 것이 좋아진 것
                .andExpect(jsonPath("$.data.change.stressScore").value(-16.0))
                .andExpect(jsonPath("$.data.endedAt").isNotEmpty());
    }

    @Test
    @DisplayName("값이 없는 지표는 변화량도 비운다")
    void nullMetricsProduceNullChange() throws Exception {
        Long preId = measurement(88, null, null);
        Long sessionId = startSession(preId);
        Long postId = measurement(74, 29.0, 62.0);

        mockMvc.perform(patch(SESSIONS + "/" + sessionId + "/complete")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"postMeasurementId":%d}
                                """.formatted(postId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.change.hr").value(-14.0))
                .andExpect(jsonPath("$.data.change.hrv").doesNotExist())
                .andExpect(jsonPath("$.data.change.stressScore").doesNotExist());
    }

    @Test
    @DisplayName("이미 끝난 세션을 다시 끝내면 409")
    void completeTwice() throws Exception {
        Long preId = measurement(88, 24.0, 78.0);
        Long sessionId = startSession(preId);
        Long postId = measurement(74, 29.0, 62.0);
        String body = """
                {"postMeasurementId":%d}
                """.formatted(postId);

        mockMvc.perform(patch(SESSIONS + "/" + sessionId + "/complete")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());

        mockMvc.perform(patch(SESSIONS + "/" + sessionId + "/complete")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error.code").value("SESSION_ALREADY_COMPLETED"));
    }

    @Test
    @DisplayName("없는 측정으로 세션을 시작하면 404")
    void startWithUnknownMeasurement() throws Exception {
        mockMvc.perform(post(SESSIONS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"preMeasurementId":99999}
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("남의 측정으로는 세션을 시작할 수 없다")
    void cannotUseOthersMeasurement() throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"other-s@test.com","password":"password123","nickname":"o"}
                        """));
        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"other-s@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = login.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        String otherToken = login.substring(start, login.indexOf('"', start));

        Long myMeasurementId = measurement(88, 24.0, 78.0);

        mockMvc.perform(post(SESSIONS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"preMeasurementId":%d}
                                """.formatted(myMeasurementId)))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("세션 이력을 조회한다")
    void findHistory() throws Exception {
        startSession(measurement(88, 24.0, 78.0));
        startSession(measurement(90, 22.0, 80.0));

        mockMvc.perform(get(SESSIONS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @Test
    @DisplayName("토큰 없이 세션을 시작하면 401")
    void requiresAuth() throws Exception {
        mockMvc.perform(post(SESSIONS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"preMeasurementId":1}
                                """))
                .andExpect(status().isUnauthorized());
    }
}
