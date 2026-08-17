package org.exaple.breath_care.calendar.push;

import org.exaple.breath_care.breathing.BreathingPreset;
import org.exaple.breath_care.breathing.BreathingRecommender;
import org.exaple.breath_care.calendar.CalendarEvent;
import org.springframework.stereotype.Component;

/**
 * 알림 문구 생성. 지금은 템플릿이고, 나중에 Gemini로 개인화된 문장을 얹을 자리다.
 * (명세서 5-5: Gemini는 판단이 아니라 표현·개인화만 담당)
 */
@Component
public class PushMessageFactory {

    /** 한글 음절의 시작 코드포인트. 받침 여부를 계산하는 데 쓴다. */
    private static final char HANGUL_BASE = 0xAC00;
    private static final char HANGUL_END = 0xD7A3;
    private static final int JONGSEONG_COUNT = 28;

    public PushMessage create(CalendarEvent event, PushType pushType) {
        String noun = event.displayCategory();
        BreathingPreset preset = BreathingRecommender.recommend(event.getEventType(), pushType);

        String title;
        String body;
        if (pushType == PushType.DAY_BEFORE) {
            title = "내일 " + withSubjectParticle(noun) + " 있어요";
            body = "\"" + event.getTitle() + "\" · 자기 전 " + preset.getLabel() + "으로 머리를 식혀볼까요?";
        } else {
            title = "곧 " + withSubjectParticle(noun) + " 시작돼요";
            body = "\"" + event.getTitle() + "\" · " + preset.getLabel() + " 1분이면 충분해요.";
        }

        return new PushMessage(event.getUserId(), title, body, event.getId(), pushType, preset);
    }

    /**
     * 주격 조사를 붙인다. 받침이 있으면 "이", 없으면 "가".
     *
     * <p>"이"로 고정해 두면 "내일 발표이 있어요"가 나간다. 기본 종류만 있을 때도 틀렸지만,
     * 사용자가 카테고리 이름을 직접 짓게 되면서 더는 넘길 수 없게 됐다.
     * ("동아리이 있어요")
     */
    private String withSubjectParticle(String noun) {
        if (noun == null || noun.isBlank()) {
            return "일정이";
        }
        return noun + (hasFinalConsonant(noun.charAt(noun.length() - 1)) ? "이" : "가");
    }

    /**
     * 마지막 글자에 받침이 있는지.
     *
     * <p>한글이 아니면(영문·숫자·이모지로 끝나는 카테고리) 받침이 있는 것으로 친다.
     * "MT이 있어요"는 어색해도 뜻은 통하는데, 조사가 통째로 빠지면 문장이 깨진다.
     */
    private boolean hasFinalConsonant(char last) {
        if (last < HANGUL_BASE || last > HANGUL_END) {
            return true;
        }
        return (last - HANGUL_BASE) % JONGSEONG_COUNT != 0;
    }
}
