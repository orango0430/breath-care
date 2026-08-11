package org.exaple.breath_care.device.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.exaple.breath_care.device.Platform;

public record DeviceRegisterRequest(

        @NotBlank(message = "FCM 토큰은 필수입니다.")
        @Size(max = 512, message = "FCM 토큰이 너무 깁니다.")
        String fcmToken,

        @NotNull(message = "플랫폼은 필수입니다.")
        Platform platform
) {
}
