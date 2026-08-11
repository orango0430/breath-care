package org.exaple.breath_care.user.dto;

/**
 * 로그아웃 요청. 본문 없이 호출해도 되지만, fcmToken을 함께 보내면
 * 이 기기로 더는 알림이 가지 않도록 등록까지 해제한다.
 */
public record LogoutRequest(String fcmToken) {
}
