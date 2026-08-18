package org.exaple.breath_care.calendar.push;

import org.exaple.breath_care.breathing.BreathingPreset;

/**
 * 발송할 알림 한 건.
 *
 * @param userId   받는 사람
 * @param title    알림 제목
 * @param body     알림 본문
 * @param eventId  앱이 알림을 탭했을 때 어떤 일정인지 알기 위한 값
 * @param pushType 전날 밤인지 직전인지. 앱이 어떤 세션을 열지 결정하는 데 쓴다
 * @param preset   권하는 호흡법. 알림을 탭하면 앱이 <b>바로 이 호흡 화면으로</b> 들어간다.
 *                 시안의 "맞춤 호흡 타이밍을 자동으로 제안"이 실제로 동작하는 지점이다
 */
public record PushMessage(Long userId, String title, String body, Long eventId,
                          PushType pushType, BreathingPreset preset) {
}
