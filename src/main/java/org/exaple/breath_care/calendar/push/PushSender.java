package org.exaple.breath_care.calendar.push;

/**
 * 알림 전송 통로. FCM 연동은 별도 PR에서 이 인터페이스를 구현해 갈아끼운다.
 * 스케줄러가 이 인터페이스만 알기 때문에 Firebase 설정 없이도 시점 계산·중복 방지를 완성하고 테스트할 수 있다.
 */
public interface PushSender {

    void send(PushMessage message);
}
