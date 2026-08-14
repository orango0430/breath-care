package org.exaple.breath_care.user;

import io.jsonwebtoken.Claims;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.global.security.JwtAuthenticationFilter;
import org.exaple.breath_care.user.dto.LoginRequest;
import org.exaple.breath_care.user.dto.LoginResponse;
import org.exaple.breath_care.user.dto.LogoutRequest;
import org.exaple.breath_care.user.dto.SignupRequest;
import org.exaple.breath_care.user.dto.SocialLoginRequest;
import org.exaple.breath_care.user.dto.UserResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<UserResponse>> signup(@Valid @RequestBody SignupRequest request) {
        UserResponse created = authService.signup(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    /**
     * 구글 로그인. 앱이 받아온 ID 토큰을 검증하고 우리 토큰으로 바꿔 준다.
     *
     * <p>가입과 로그인이 나뉘지 않는다. 처음이면 계정을 만들고, 같은 이메일로 자체 가입한
     * 계정이 이미 있으면 거기에 연결한다. 앱은 두 경우를 구분할 필요가 없다.
     */
    @PostMapping("/social")
    public ApiResponse<LoginResponse> socialLogin(@Valid @RequestBody SocialLoginRequest request) {
        return ApiResponse.ok(authService.socialLogin(request));
    }

    /**
     * 본문은 선택이다. fcmToken을 보내면 그 기기의 알림 등록까지 해제한다.
     * (기존 계약을 깨지 않도록 본문 없이 호출해도 그대로 동작한다)
     */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(
            @AuthenticationPrincipal Long userId,
            @RequestAttribute(JwtAuthenticationFilter.CLAIMS_ATTRIBUTE) Claims claims,
            @RequestBody(required = false) LogoutRequest request) {

        authService.logout(userId, claims, request == null ? null : request.fcmToken());
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/withdraw")
    public ApiResponse<Void> withdraw(
            @AuthenticationPrincipal Long userId,
            @RequestAttribute(JwtAuthenticationFilter.CLAIMS_ATTRIBUTE) Claims claims) {
        authService.withdraw(userId, claims);
        return ApiResponse.ok(null);
    }
}
