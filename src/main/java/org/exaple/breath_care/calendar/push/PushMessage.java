package org.exaple.breath_care.calendar.push;

/**
 * 발송할 알림 한 건.
 *
 * @param userId    받는 사람
 * @param title     알림 제목
 * @param body      알림 본문
 * @param eventId   앱이 알림을 탭했을 때 어떤 일정인지 알기 위한 값
 * @param pushType  전날 밤인지 직전인지. 앱이 어떤 세션을 열지 결정하는 데 쓴다
 */
public record PushMessage(Long userId, String title, String body, Long eventId, PushType pushType) {
}
