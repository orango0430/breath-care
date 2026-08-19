package org.exaple.breath_care.measurement;

import org.hamcrest.Matchers;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;


import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 비회원 측정. 로그인 없이 계산만 받아 가고 서버에는 아무것도 남기지 않는다.
 *
 * <p>파형은 {@link PpgWaveforms}가 72bpm으로 만든다. 값을 정확한 숫자로 못 박지 않고
 * 범위로 두는 이유는, 신호처리 상수가 실측 데이터로 조정될 예정이라 정확한 값이 조금씩
 * 움직이기 때문이다. 여기서 확인할 것은 <b>API가 제대로 된 응답을 내는가</b>이고,
 * 알고리즘의 정확성은 {@code PpgSignalProcessorTest}가 본다.
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

    @Test
    @DisplayName("토큰 없이도 측정 결과를 받는다")
    void worksWithoutToken() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.requestBody()))
                .andExpect(status().isOk())
                // 72bpm으로 만든 파형이다
                .andExpect(jsonPath("$.data.hr",
                        Matchers.closeTo(72.0, 3.0)))
                .andExpect(jsonPath("$.data.hrv").isNumber())
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
                        .content(PpgWaveforms.requestBody()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conditionScore").isNumber())
                .andExpect(jsonPath("$.data.conditionScore",
                        Matchers.allOf(
                                Matchers.greaterThanOrEqualTo(50.0),
                                Matchers.lessThanOrEqualTo(96.0))));
    }

    @Test
    @DisplayName("비회원 측정은 서버에 저장되지 않는다")
    void storesNothing() throws Exception {
        long measurementsBefore = measurementRepository.count();
        long signalsBefore = signalRepository.count();

        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.requestBody()))
                .andExpect(status().isOk());

        assertThat(measurementRepository.count()).isEqualTo(measurementsBefore);
        assertThat(signalRepository.count()).isEqualTo(signalsBefore);
    }

    /**
     * V14에서 요청의 recentHrs를 걷어냈다. 이미 배포된 앱이 그 필드를 계속 보내도
     * 400으로 튕기면 안 된다. 스프링 부트가 모르는 필드를 무시하도록 설정해 두는 데
     * 기대고 있어서, 그 설정이 바뀌면 여기서 먼저 걸린다.
     */
    @Test
    @DisplayName("예전 앱이 recentHrs를 보내도 무시하고 정상 처리한다")
    void ignoresRemovedRecentHrsField() throws Exception {
        String body = PpgWaveforms.requestBody().trim();
        String withExtraField = body.substring(0, body.length() - 1) + ",\"recentHrs\":[70.0,71.0]}";

        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(withExtraField))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conditionScore").isNumber());
    }

    @Test
    @DisplayName("회원과 같은 품질 기준을 적용한다 — 프레임이 모자라면 422")
    void rejectsDroppedFrames() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.droppedFrameBody(60, 30, 500)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("손가락을 대지 않은 평평한 신호는 422")
    void rejectsFlatSignal() throws Exception {
        mockMvc.perform(post(ANALYZE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.flatBody(60, 30)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error.code").value("POOR_SIGNAL_QUALITY"));
    }

    @Test
    @DisplayName("인증 없이 열린 건 이 경로의 POST뿐이다")
    void onlyAnalyzeIsOpen() throws Exception {
        // 같은 prefix의 저장용 엔드포인트는 여전히 토큰을 요구한다
        mockMvc.perform(post("/api/measurements")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PpgWaveforms.requestBody()))
                .andExpect(status().isUnauthorized());
    }
}
