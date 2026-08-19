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

    /**
     * 파형은 {@link PpgWaveforms}가 만든다. 신호처리가 진짜로 돌기 때문에 아무 값이나
     * 보내면 심박수가 안 나오거나 품질 게이트에 걸린다.
     */
    private String requestBody() {
        return PpgWaveforms.requestBody();
    }

    @Test
    @DisplayName("측정 결과를 보내면 심박수·HRV·품질을 돌려준다")
    void measure() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").isNumber())
                // 72bpm으로 만든 파형이다. 신호처리가 그걸 되찾아야 한다
                .andExpect(jsonPath("$.data.hr",
                        org.hamcrest.Matchers.closeTo(72.0, 3.0)))
                .andExpect(jsonPath("$.data.hrv").isNumber())
                .andExpect(jsonPath("$.data.quality").value("GOOD"))
                .andExpect(jsonPath("$.data.measuredAt").isNotEmpty())
                // 컨디션 지수는 기준선이 필요 없어 첫 측정부터 나온다
                .andExpect(jsonPath("$.data.conditionScore").isNumber());
    }

    @Test
    @DisplayName("맥동이 없는 평평한 신호는 422 — 손가락을 안 댄 경우다")
    void rejectsFlatSignal() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.flatBody(60, 30)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("원시 파형을 함께 저장한다 (나중에 알고리즘 재검증에 쓴다)")
    void storesRawSignal() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody()))
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
                        .content(PpgWaveforms.droppedFrameBody(60, 30, 500)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("측정이 너무 짧으면 422")
    void rejectsTooShortMeasurement() throws Exception {
        mockMvc.perform(post(MEASUREMENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.requestBody(15, 30)))
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
                        .content(requestBody()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("측정 이력을 최신순으로 조회한다")
    void findHistory() throws Exception {
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody()));
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody()));

        mockMvc.perform(get(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @Test
    @DisplayName("남의 측정은 이력에 섞이지 않는다")
    void historyIsScopedToUser() throws Exception {
        mockMvc.perform(post(MEASUREMENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(requestBody()));

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
