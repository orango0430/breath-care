package org.exaple.breath_care.statistics;

import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementQuality;
import org.exaple.breath_care.measurement.MeasurementRepository;
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

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class StatisticsControllerTest {

    private static final String SUMMARY = "/api/statistics/summary";
    private static final String DAILY = "/api/statistics/daily";

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
                                {"email":"stat@test.com","password":"password123","nickname":"stat"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        int idStart = signup.indexOf("\"id\":") + "\"id\":".length();
        int idEnd = idStart;
        while (Character.isDigit(signup.charAt(idEnd))) {
            idEnd++;
        }
        userId = Long.parseLong(signup.substring(idStart, idEnd));

        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"stat@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = login.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        token = login.substring(start, login.indexOf('"', start));
    }

    /** 한국 시간 기준 특정 날짜·시각에 측정을 남긴다. */
    private void measurementAt(LocalDate date, int hour, double hr, Double hrv, Double conditionScore) {
        Instant at = date.atTime(LocalTime.of(hour, 0)).atZone(DayRange.ZONE).toInstant();
        measurementRepository.save(Measurement.create(
                userId, hr, hrv, hrv, conditionScore, MeasurementQuality.GOOD, at));
    }

    @Test
    @DisplayName("기간 요약은 평균·최고·최소를 낸다")
    void summary() throws Exception {
        LocalDate day = LocalDate.now(DayRange.ZONE);
        measurementAt(day, 9, 68, 16.0, 20.0);
        measurementAt(day, 13, 94, 32.0, 88.0);
        measurementAt(day, 18, 84, 18.0, 60.0);

        mockMvc.perform(get(SUMMARY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.measurementCount").value(3))
                .andExpect(jsonPath("$.data.hr.avg").value(82.0))
                .andExpect(jsonPath("$.data.hr.max").value(94.0))
                .andExpect(jsonPath("$.data.hr.min").value(68.0))
                .andExpect(jsonPath("$.data.hrv.max").value(32.0))
                .andExpect(jsonPath("$.data.hrv.min").value(16.0))
                .andExpect(jsonPath("$.data.conditionScore.max").value(88.0));
    }

    @Test
    @DisplayName("측정이 없으면 값은 비고 개수는 0이다")
    void summaryWithoutMeasurements() throws Exception {
        mockMvc.perform(get(SUMMARY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.measurementCount").value(0))
                .andExpect(jsonPath("$.data.hr.avg").doesNotExist())
                .andExpect(jsonPath("$.data.hr.count").value(0));
    }

    @Test
    @DisplayName("값이 비어 있는 지표는 그 지표만 집계에서 빠진다")
    void summarySkipsNullMetrics() throws Exception {
        LocalDate day = LocalDate.now(DayRange.ZONE);
        measurementAt(day, 9, 70, null, null);
        measurementAt(day, 10, 80, 20.0, 50.0);

        mockMvc.perform(get(SUMMARY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.measurementCount").value(2))
                .andExpect(jsonPath("$.data.hr.count").value(2))
                // HRV는 한 건만 값이 있다
                .andExpect(jsonPath("$.data.hrv.count").value(1))
                .andExpect(jsonPath("$.data.hrv.avg").value(20.0));
    }

    @Test
    @DisplayName("일별 통계는 기본 7일치를 빠짐없이 준다")
    void dailyReturnsSevenDays() throws Exception {
        mockMvc.perform(get(DAILY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(7));
    }

    @Test
    @DisplayName("측정이 없는 날도 빈 값으로 자리를 채운다")
    void dailyKeepsEmptyDays() throws Exception {
        LocalDate today = LocalDate.now(DayRange.ZONE);
        measurementAt(today, 10, 80, 20.0, 50.0);

        mockMvc.perform(get(DAILY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(7))
                // 가장 오래된 날(6일 전)에는 측정이 없다
                .andExpect(jsonPath("$.data[0].measurementCount").value(0))
                .andExpect(jsonPath("$.data[0].hr").doesNotExist())
                // 마지막 날이 오늘
                .andExpect(jsonPath("$.data[6].measurementCount").value(1))
                .andExpect(jsonPath("$.data[6].hr").value(80.0))
                .andExpect(jsonPath("$.data[6].date").value(today.toString()));
    }

    @Test
    @DisplayName("같은 날 여러 번 측정하면 평균으로 묶인다")
    void dailyAveragesSameDay() throws Exception {
        LocalDate today = LocalDate.now(DayRange.ZONE);
        measurementAt(today, 9, 70, 20.0, 40.0);
        measurementAt(today, 21, 90, 30.0, 60.0);

        mockMvc.perform(get(DAILY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[6].measurementCount").value(2))
                .andExpect(jsonPath("$.data[6].hr").value(80.0))
                .andExpect(jsonPath("$.data[6].hrv").value(25.0));
    }

    @Test
    @DisplayName("밤 늦은 측정도 한국 시간 기준 같은 날로 묶인다")
    void dailyUsesKoreanDateBoundary() throws Exception {
        LocalDate today = LocalDate.now(DayRange.ZONE);
        // 23시(KST)는 UTC로는 14시라 UTC 기준으로 잘라도 같은 날이지만,
        // 익일 새벽 1시(KST)는 UTC로 전날 16시가 되어 UTC 기준이면 어제로 밀린다.
        measurementAt(today, 23, 88, 20.0, 70.0);

        mockMvc.perform(get(DAILY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[6].date").value(today.toString()))
                .andExpect(jsonPath("$.data[6].measurementCount").value(1));
    }

    @Test
    @DisplayName("남의 측정은 통계에 섞이지 않는다")
    void statisticsAreScopedToUser() throws Exception {
        measurementAt(LocalDate.now(DayRange.ZONE), 10, 80, 20.0, 50.0);

        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"stat-other@test.com","password":"password123","nickname":"o"}
                        """));
        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"stat-other@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = login.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        String otherToken = login.substring(start, login.indexOf('"', start));

        mockMvc.perform(get(SUMMARY).header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
                .andExpect(jsonPath("$.data.measurementCount").value(0));
    }

    @Test
    @DisplayName("토큰 없이 통계를 부르면 401")
    void requiresAuth() throws Exception {
        mockMvc.perform(get(SUMMARY))
                .andExpect(status().isUnauthorized());
    }
}
