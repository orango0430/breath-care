package org.exaple.breath_care.breathing;

import org.exaple.breath_care.calendar.EventType;
import org.exaple.breath_care.calendar.push.PushType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 호흡 추천 규칙. 스프링 없이 도는 순수 규칙이라 컨텍스트를 띄우지 않는다.
 */
class BreathingRecommenderTest {

    @Test
    @DisplayName("직전 30분에는 일정 종류에 맞는 호흡을 권한다")
    void beforeEventDependsOnEventType() {
        assertThat(BreathingRecommender.recommend(EventType.PRESENTATION, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.PHYSIOLOGICAL_SIGH);
        assertThat(BreathingRecommender.recommend(EventType.EXAM, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.BOX);
        assertThat(BreathingRecommender.recommend(EventType.INTERVIEW, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.RESONANCE);
    }

    @Test
    @DisplayName("전날 밤에는 종류를 가리지 않고 4-7-8을 권한다")
    void nightIsAlwaysFourSevenEight() {
        for (EventType type : EventType.values()) {
            assertThat(BreathingRecommender.recommend(type, PushType.DAY_BEFORE))
                    .as("%s", type)
                    .isEqualTo(BreathingPreset.FOUR_SEVEN_EIGHT);
        }
    }

    @Test
    @DisplayName("전날 밤에 각성 호흡은 절대 나오지 않는다")
    void neverRecommendsAwakeningAtNight() {
        // 8종 중 유일하게 들숨이 날숨보다 긴 호흡이다. 밤 알림에 나가면 사람을 못 자게 만든다.
        for (EventType type : EventType.values()) {
            assertThat(BreathingRecommender.recommend(type, PushType.DAY_BEFORE))
                    .as("%s 전날 밤", type)
                    .isNotEqualTo(BreathingPreset.AWAKENING);
        }
        assertThat(BreathingRecommender.recommend(null, PushType.DAY_BEFORE))
                .isNotEqualTo(BreathingPreset.AWAKENING);
    }

    @Test
    @DisplayName("마감·기타는 기본 호흡을 권한다")
    void deadlineAndEtcFallBack() {
        assertThat(BreathingRecommender.recommend(EventType.DEADLINE, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.DEFAULT);
        assertThat(BreathingRecommender.recommend(EventType.ETC, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.DEFAULT);
    }

    @Test
    @DisplayName("종류를 모르는 일정(폰 캘린더 동기화)도 추천이 나온다")
    void nullEventTypeStillRecommends() {
        // null을 그냥 두면 여기서 NPE가 나고 알림이 통째로 멈춘다.
        assertThat(BreathingRecommender.recommend(null, PushType.BEFORE_30M))
                .isEqualTo(BreathingPreset.DEFAULT);
        assertThat(BreathingRecommender.recommend(null, PushType.DAY_BEFORE))
                .isEqualTo(BreathingPreset.FOUR_SEVEN_EIGHT);
    }

    @Test
    @DisplayName("어떤 조합에도 추천이 비지 않는다")
    void everyCombinationHasARecommendation() {
        for (PushType pushType : PushType.values()) {
            for (EventType eventType : EventType.values()) {
                assertThat(BreathingRecommender.recommend(eventType, pushType))
                        .as("%s / %s", eventType, pushType)
                        .isNotNull();
            }
        }
    }
}
