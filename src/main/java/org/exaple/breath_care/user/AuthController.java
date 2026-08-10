package org.exaple.breath_care.user;

import io.jsonwebtoken.Claims;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.global.security.JwtAuthenticationFilter;
import org.exaple.breath_care.user.dto.LoginRequest;
import org.exaple.breath_care.user.dto.LoginResponse;
import org.exaple.breath_care.user.dto.SignupRequest;
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

    @PostMapping("/logout")
    public ApiResponse<Void> logout(
            @RequestAttribute(JwtAuthenticationFilter.CLAIMS_ATTRIBUTE) Claims claims) {
        authService.logout(claims);
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
