package org.exaple.breath_care.calendar.push;

import org.exaple.breath_care.breathing.BreathingPreset;
import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.EventType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 알림 문구. 스프링 없이 돈다.
 */
class PushMessageFactoryTest {

    private final PushMessageFactory factory = new PushMessageFactory();

    private CalendarEvent event(String title, EventType type, String customCategory) {
        return CalendarEvent.create(1L, title, type, customCategory, Instant.parse("2026-09-15T05:00:00Z"));
    }

    @Test
    @DisplayName("받침 없는 카테고리에는 '가'가 붙는다")
    void noFinalConsonantTakesGa() {
        // 예전에는 "이"로 고정돼 있어 "내일 발표이 있어요"가 나갔다.
        PushMessage message = factory.create(event("최종 발표", EventType.PRESENTATION, null), PushType.DAY_BEFORE);

        assertThat(message.title()).isEqualTo("내일 발표가 있어요");
    }

    @Test
    @DisplayName("받침 있는 카테고리에는 '이'가 붙는다")
    void finalConsonantTakesI() {
        assertThat(factory.create(event("중간고사", EventType.EXAM, null), PushType.DAY_BEFORE).title())
                .isEqualTo("내일 시험이 있어요");
        assertThat(factory.create(event("1차 면접", EventType.INTERVIEW, null), PushType.DAY_BEFORE).title())
                .isEqualTo("내일 면접이 있어요");
    }

    @Test
    @DisplayName("직접 만든 카테고리 이름이 문구에 그대로 쓰인다")
    void usesCustomCategory() {
        PushMessage message = factory.create(event("정기 공연", EventType.ETC, "동아리"), PushType.BEFORE_30M);

        assertThat(message.title()).isEqualTo("곧 동아리가 시작돼요");
    }

    @Test
    @DisplayName("한글이 아닌 이름으로 끝나도 조사가 빠지지 않는다")
    void nonHangulStillGetsParticle() {
        PushMessage message = factory.create(event("여름 MT", EventType.ETC, "MT"), PushType.DAY_BEFORE);

        assertThat(message.title()).isEqualTo("내일 MT이 있어요");
    }

    @Test
    @DisplayName("본문에 권하는 호흡 이름이 들어간다")
    void bodyNamesThePreset() {
        PushMessage before = factory.create(event("최종 발표", EventType.PRESENTATION, null), PushType.BEFORE_30M);
        assertThat(before.body()).contains("생리학적 한숨", "최종 발표");

        PushMessage night = factory.create(event("중간고사", EventType.EXAM, null), PushType.DAY_BEFORE);
        assertThat(night.body()).contains("4-7-8 호흡");
    }

    @Test
    @DisplayName("알림에 프리셋이 실려 앱이 바로 그 호흡을 열 수 있다")
    void carriesPreset() {
        assertThat(factory.create(event("중간고사", EventType.EXAM, null), PushType.BEFORE_30M).preset())
                .isEqualTo(BreathingPreset.BOX);
        assertThat(factory.create(event("중간고사", EventType.EXAM, null), PushType.DAY_BEFORE).preset())
                .isEqualTo(BreathingPreset.FOUR_SEVEN_EIGHT);
    }

    @Test
    @DisplayName("종류도 카테고리도 없으면 '일정'으로 만든다")
    void fallsBackToDefaultNoun() {
        assertThat(factory.create(event("제목만 있는 일정", null, null), PushType.DAY_BEFORE).title())
                .isEqualTo("내일 일정이 있어요");
    }
}
