package org.exaple.breath_care.report;

import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementQuality;
import org.exaple.breath_care.measurement.MeasurementRepository;
import org.exaple.breath_care.report.generate.ReportContent;
import org.exaple.breath_care.report.generate.ReportGenerator;
import org.exaple.breath_care.report.generate.ReportInput;
import org.exaple.breath_care.statistics.DayRange;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 주간 AI 리포트.
 *
 * <p>이 테스트가 지키려는 것은 문구 품질이 아니라 <b>호출을 아끼는 규칙</b>이다.
 * 그래서 생성기를 대역으로 두고, 어느 경로에서 호출이 일어나고 어느 경로에서 안 일어나는지를 센다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class ReportControllerTest {

    private static final String WEEKLY = "/api/reports/weekly";

    private static final ReportContent GENERATED = new ReportContent(
            "이번 주는 대체로 안정적이었어요.",
            List.of("수요일 오후에 심박수가 높았어요", "주말에는 HRV가 올라갔어요"),
            List.of("발표 30분 전에 4-7-8 호흡을 해보세요"));

    @Autowired
    MockMvc mockMvc;
    @Autowired
    MeasurementRepository measurementRepository;
    @Autowired
    AiReportRepository aiReportRepository;

    @MockitoBean
    ReportGenerator reportGenerator;

    private String token;
    private Long userId;

    @BeforeEach
    void setUp() throws Exception {
        String signup = mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"report@test.com","password":"password123","nickname":"report"}
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        userId = Long.parseLong(extract(signup, "\"id\":", ','));

        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"report@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        token = extract(login, "\"accessToken\":\"", '"');

        given(reportGenerator.generate(any(ReportInput.class))).willReturn(GENERATED);
        given(reportGenerator.modelName()).willReturn("test-model");
    }

    private String extract(String json, String key, char end) {
        int start = json.indexOf(key) + key.length();
        return json.substring(start, json.indexOf(end, start));
    }

    /** 이번 주 안에 측정을 남긴다. 리포트 구간이 오늘 포함 최근 7일이라 오늘로 넣으면 항상 걸린다. */
    private void measurements(int count) {
        LocalDate today = LocalDate.now(DayRange.ZONE);
        for (int i = 0; i < count; i++) {
            Instant at = today.atTime(LocalTime.of(9, 0)).atZone(DayRange.ZONE).toInstant().plusSeconds(i);
            measurementRepository.save(Measurement.create(
                    userId, 70.0 + i, 35.0, 40.0, MeasurementQuality.GOOD, at));
        }
    }

    @Test
    @DisplayName("측정이 부족하면 생성기를 부르지 않고 막는다")
    void insufficientData() throws Exception {
        measurements(2);

        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("INSUFFICIENT_DATA"));

        verify(reportGenerator, never()).generate(any());
    }

    @Test
    @DisplayName("측정이 충분하면 리포트를 만들어 저장한다")
    void generate() throws Exception {
        measurements(3);

        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.summary").value(GENERATED.summary()))
                .andExpect(jsonPath("$.data.insights.length()").value(2))
                .andExpect(jsonPath("$.data.advice[0]").value(GENERATED.advice().get(0)))
                .andExpect(jsonPath("$.data.model").value("test-model"))
                // 시안 맨 아래 안내 문구. 모델이 만든 게 아니라 서버가 고정으로 붙인다
                .andExpect(jsonPath("$.data.disclaimer").value(
                        org.hamcrest.Matchers.containsString("의학적 진단이 아니에요")))
                // 방금 만들었으니 캐시가 아니다
                .andExpect(jsonPath("$.data.cached").value(false));

        verify(reportGenerator, times(1)).generate(any());
    }

    @Test
    @DisplayName("같은 주에 다시 생성하면 저장된 걸 주고 생성기를 다시 부르지 않는다")
    void reuseWithinSameWeek() throws Exception {
        measurements(3);

        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cached").value(true));

        // 두 번 요청했지만 호출은 한 번뿐이다. 이게 이 기능의 핵심이다.
        verify(reportGenerator, times(1)).generate(any());
    }

    @Test
    @DisplayName("refresh=true여도 쿨다운 안이면 다시 만들지 않는다")
    void refreshWithinCooldown() throws Exception {
        measurements(3);
        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(post(WEEKLY).param("refresh", "true")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cached").value(true));

        verify(reportGenerator, times(1)).generate(any());
    }

    @Test
    @DisplayName("쿨다운이 지난 뒤 refresh=true면 같은 행을 덮어쓴다")
    void refreshAfterCooldown() throws Exception {
        measurements(3);
        DayRange week = DayRange.of(null, null);
        aiReportRepository.save(AiReport.create(userId, week.from(), week.to(),
                new ReportContent("예전 요약", List.of("예전"), List.of("예전")),
                "old-model", Instant.now().minus(7, ChronoUnit.HOURS)));

        mockMvc.perform(post(WEEKLY).param("refresh", "true")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.summary").value(GENERATED.summary()))
                .andExpect(jsonPath("$.data.cached").value(false));

        verify(reportGenerator, times(1)).generate(any());
        // 기간당 한 행을 유지한다. 재생성할 때마다 쌓이면 안 된다.
        org.assertj.core.api.Assertions.assertThat(aiReportRepository.findAll()).hasSize(1);
    }

    @Test
    @DisplayName("조회는 리포트가 없으면 404이고, 절대 생성기를 부르지 않는다")
    void findBeforeGenerating() throws Exception {
        measurements(3);

        mockMvc.perform(get(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("NOT_FOUND"));

        verify(reportGenerator, never()).generate(any());
    }

    @Test
    @DisplayName("조회는 저장된 리포트를 그대로 준다")
    void findAfterGenerating() throws Exception {
        measurements(3);
        mockMvc.perform(post(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(get(WEEKLY).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.summary").value(GENERATED.summary()))
                .andExpect(jsonPath("$.data.cached").value(true));

        verify(reportGenerator, times(1)).generate(any());
    }

    @Test
    @DisplayName("비회원은 리포트를 쓸 수 없다")
    void requiresAuth() throws Exception {
        mockMvc.perform(get(WEEKLY)).andExpect(status().isUnauthorized());
        mockMvc.perform(post(WEEKLY)).andExpect(status().isUnauthorized());

        verify(reportGenerator, never()).generate(any());
    }
}
