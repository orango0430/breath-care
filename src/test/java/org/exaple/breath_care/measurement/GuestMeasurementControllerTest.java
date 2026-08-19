package org.exaple.breath_care.measurement;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 비회원 측정. 로그인 없이 계산만 받아 가고 서버에는 아무것도 남기지 않는다.
 * 신호처리가 스텁이라 심박수·HRV는 고정값으로 나온다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class GuestMeasurementControllerTest {

    private static final String ANALYZE = "/api/measurements/analyze";

    /** 스텁의 SDNN 32.0 → 32.0 × 1.4 + 40 = 84.8 */
    private static final double STUB_CONDITION_SCORE = 84.8;

    @Autowired
    MockMvc mockMvc;
    @Autowired
    MeasurementRepository measurementRepository;
    @Autowired
    MeasurementSignalRepository signalRepository;

    /** fps 30으로 frameCount 개의 파형을 만든다. */
    private String requestBody(int durationSec, int frameCount) {
        String samples = IntStream.range(0, frameCount)
                .mapToObj(i -> String.valueOf(120.0 + (i % 10) * 0.5))
                .collect(Collectors.joining(","));

        return """
                {"samples":[%s],"fps":30,"durationSec":%d}
                """.formatted(samples, durationSec);
    }

    @Test
    @DisplayName("토큰 없이도 측정 결과를 받는다")
    void worksWithoutToken() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.hr").value(72.0))
                .andExpect(jsonPath("$.data.hrv").value(35.0))
                .andExpect(jsonPath("$.data.quality").value("GOOD"))
                .andExpect(jsonPath("$.data.measuredAt").isNotEmpty())
                // 저장하지 않았으니 가리킬 id가 없다
                .andExpect(jsonPath("$.data.id").doesNotExist());
    }

    /**
     * 이 테스트가 V14의 핵심이다.
     *
     * <p>이전 지표(스트레스 지수)는 개인 기준선을 만들려고 과거 측정 5회를 요구했다.
     * 행사에서 한 번씩 측정하는 사람에게는 영영 null이었다. 컨디션 지수는 이번 측정의
     * HRV만으로 나오므로 <b>이력이 하나도 없어도 첫 측정부터 숫자가 나온다.</b>
     */
    @Test
    @DisplayName("이력이 없어도 첫 측정부터 컨디션 지수가 나온다")
    void conditionScoreOnFirstMeasurement() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conditionScore").value(STUB_CONDITION_SCORE));
    }

    @Test
    @DisplayName("비회원 측정은 서버에 저장되지 않는다")
    void storesNothing() throws Exception {
        long measurementsBefore = measurementRepository.count();
        long signalsBefore = signalRepository.count();

        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isOk());

        assertThat(measurementRepository.count()).isEqualTo(measurementsBefore);
        assertThat(signalRepository.count()).isEqualTo(signalsBefore);
    }

    /**
     * V14에서 요청의 recentHrs를 걷어냈다. 이미 배포된 앱이 그 필드를 계속 보내도
     * 400으로 튕기면 안 된다. 스프링 부트가 모르는 필드를 무시하도록 설정해 두는 데 기대고 있어서,
     * 그 설정이 바뀌면 여기서 먼저 걸린다.
     */
    @Test
    @DisplayName("예전 앱이 recentHrs를 보내도 무시하고 정상 처리한다")
    void ignoresRemovedRecentHrsField() throws Exception {
        String samples = IntStream.range(0, 1800)
                .mapToObj(i -> String.valueOf(120.0 + (i % 10) * 0.5))
                .collect(Collectors.joining(","));

        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"samples":[%s],"fps":30,"durationSec":60,"recentHrs":[70.0,71.0]}
                                """.formatted(samples)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conditionScore").value(STUB_CONDITION_SCORE));
    }

    @Test
    @DisplayName("회원과 같은 품질 기준을 적용한다 — 프레임이 모자라면 422")
    void rejectsDroppedFrames() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 500)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("인증 없이 열린 건 이 경로의 POST뿐이다")
    void onlyAnalyzeIsOpen() throws Exception {
        // 같은 prefix의 저장용 엔드포인트는 여전히 토큰을 요구한다
        mockMvc.perform(post("/api/measurements")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody(60, 1800)))
                .andExpect(status().isUnauthorized());
    }
}
