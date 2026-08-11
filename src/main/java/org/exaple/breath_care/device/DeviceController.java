package org.exaple.breath_care.device;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.device.dto.DeviceRegisterRequest;
import org.exaple.breath_care.device.dto.DeviceTokenRequest;
import org.exaple.breath_care.global.response.ApiResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceService deviceService;

    /**
     * 기기 등록. 로그인 직후와 FCM 토큰이 갱신될 때마다 호출한다.
     * 같은 토큰으로 여러 번 불러도 안전하다(멱등).
     */
    @PostMapping
    public ApiResponse<Void> register(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody DeviceRegisterRequest request) {

        deviceService.register(userId, request);
        return ApiResponse.ok(null);
    }

    /** 기기 해제. 로그아웃에서도 같은 일을 하지만, 알림만 끄고 싶을 때 쓸 수 있게 열어둔다. */
    @DeleteMapping
    public ApiResponse<Void> unregister(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody DeviceTokenRequest request) {

        deviceService.unregister(userId, request.fcmToken());
        return ApiResponse.ok(null);
    }
}
