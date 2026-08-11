package org.exaple.breath_care.calendar.push;

import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.EventType;
import org.springframework.stereotype.Component;

/**
 * 알림 문구 생성. 지금은 템플릿이고, 나중에 Gemini로 개인화된 문장을 얹을 자리다.
 * (명세서 5-5: Gemini는 판단이 아니라 표현·개인화만 담당)
 */
@Component
public class PushMessageFactory {

    public PushMessage create(CalendarEvent event, PushType pushType) {
        String noun = nounOf(event.getEventType());

        String title;
        String body;
        if (pushType == PushType.DAY_BEFORE) {
            title = "내일 " + noun + "이 있어요";
            body = "\"" + event.getTitle() + "\" · 자기 전 호흡으로 머리를 식혀볼까요?";
        } else {
            title = "곧 " + noun + "이 시작돼요";
            body = "\"" + event.getTitle() + "\" · 1분 호흡으로 긴장을 낮춰봐요.";
        }

        return new PushMessage(event.getUserId(), title, body, event.getId(), pushType);
    }

    private String nounOf(EventType type) {
        if (type == null) {
            return "일정";
        }
        return switch (type) {
            case EXAM -> "시험";
            case PRESENTATION -> "발표";
            case INTERVIEW -> "면접";
            case DEADLINE -> "마감";
            case ETC -> "일정";
        };
    }
}
