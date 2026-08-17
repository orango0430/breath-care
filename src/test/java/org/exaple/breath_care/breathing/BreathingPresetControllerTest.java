package org.exaple.breath_care.breathing;

import org.exaple.breath_care.calendar.EventType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class BreathingPresetControllerTest {

    private static final String PRESETS = "/api/breathing/presets";

    @Autowired
    MockMvc mockMvc;

    @Test
    @DisplayName("비회원도 호흡법 목록을 받을 수 있다")
    void listWithoutLogin() throws Exception {
        mockMvc.perform(get(PRESETS))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(8))
                .andExpect(jsonPath("$.data[0].name").value("FOUR_SEVEN_EIGHT"))
                .andExpect(jsonPath("$.data[0].label").value("4-7-8 호흡"))
                .andExpect(jsonPath("$.data[0].cycleSeconds").value(19.0));
    }

    @Test
    @DisplayName("일정 종류를 주면 그 종류에 배정된 것만 온다")
    void filterByEventType() throws Exception {
        mockMvc.perform(get(PRESETS).param("eventType", "INTERVIEW"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[*].name")
                        .value(org.hamcrest.Matchers.containsInAnyOrder("RESONANCE", "RELAX_FOUR_SIX")));
    }

    @Test
    @DisplayName("배정된 프리셋이 없는 종류는 기본값 하나가 온다")
    void unassignedEventTypeFallsBack() throws Exception {
        mockMvc.perform(get(PRESETS).param("eventType", "DEADLINE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].name").value(BreathingPreset.DEFAULT.name()));
    }

    @Test
    @DisplayName("생리학적 한숨은 들숨이 두 번 연달아 나온다")
    void sighHasTwoConsecutiveInhales() {
        // "들숨·멈춤·날숨" 세 칸을 가정하면 이 프리셋을 표현할 수 없다.
        // 앱도 순서대로 재생해야 하므로 계약으로 못 박아 둔다.
        assertThat(BreathingPreset.PHYSIOLOGICAL_SIGH.getSteps())
                .extracting(BreathStep::phase)
                .containsExactly(BreathPhase.INHALE, BreathPhase.INHALE, BreathPhase.EXHALE);
    }

    @Test
    @DisplayName("각성 호흡만 들숨이 날숨보다 길다")
    void onlyAwakeningInhalesLonger() {
        for (BreathingPreset preset : BreathingPreset.values()) {
            double inhale = secondsOf(preset, BreathPhase.INHALE);
            double exhale = secondsOf(preset, BreathPhase.EXHALE);

            if (preset == BreathingPreset.AWAKENING) {
                assertThat(inhale).as("각성 호흡은 들숨이 길어야 한다").isGreaterThan(exhale);
            } else {
                assertThat(inhale).as("%s는 날숨이 들숨 이상이어야 한다", preset)
                        .isLessThanOrEqualTo(exhale);
            }
        }
    }

    private double secondsOf(BreathingPreset preset, BreathPhase phase) {
        return preset.getSteps().stream()
                .filter(step -> step.phase() == phase)
                .mapToDouble(BreathStep::seconds)
                .sum();
    }

    @Test
    @DisplayName("모든 프리셋은 이름·설명·주기를 갖는다")
    void everyPresetIsComplete() {
        for (BreathingPreset preset : BreathingPreset.values()) {
            assertThat(preset.getLabel()).as("%s label", preset).isNotBlank();
            assertThat(preset.getDescription()).as("%s description", preset).isNotBlank();
            assertThat(preset.getSteps()).as("%s steps", preset).isNotEmpty();
            assertThat(preset.cycleSeconds()).as("%s cycle", preset).isGreaterThan(0);
        }
    }

    @Test
    @DisplayName("일정 종류를 모르면 기본 프리셋을 준다")
    void nullEventTypeFallsBack() {
        assertThat(BreathingPreset.forEventType(null)).containsExactly(BreathingPreset.DEFAULT);
    }

    @Test
    @DisplayName("발표·시험·면접에는 배정된 프리셋이 있다")
    void mainEventTypesHavePresets() {
        for (EventType type : List.of(EventType.PRESENTATION, EventType.EXAM, EventType.INTERVIEW)) {
            assertThat(BreathingPreset.forEventType(type))
                    .as("%s", type)
                    .isNotEmpty()
                    .doesNotContainNull()
                    .allMatch(preset -> preset.getSuitedFor() == type);
        }
    }
}
