package org.exaple.breath_care.device.dto;

import jakarta.validation.constraints.NotBlank;

/** 기기 해제·로그아웃처럼 토큰만 필요한 요청. */
public record DeviceTokenRequest(

        @NotBlank(message = "FCM 토큰은 필수입니다.")
        String fcmToken
) {
}
