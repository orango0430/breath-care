package org.exaple.breath_care.user;

import io.jsonwebtoken.Claims;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.device.DeviceService;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.global.security.JwtTokenProvider;
import org.exaple.breath_care.global.security.TokenRevocationService;
import org.exaple.breath_care.user.dto.LoginRequest;
import org.exaple.breath_care.user.dto.LoginResponse;
import org.exaple.breath_care.user.dto.SignupRequest;
import org.exaple.breath_care.user.dto.UserResponse;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final TokenRevocationService revocationService;
    private final DeviceService deviceService;

    /**
     * 존재하지 않는 이메일일 때 비교 대상으로 쓰는 더미 해시.
     * 임의의 비밀번호로 한 번만 만들어 두고 재사용한다. (매 로그인마다 encode 하면 낭비)
     */
    private String dummyHash;

    @PostConstruct
    void initDummyHash() {
        this.dummyHash = passwordEncoder.encode(UUID.randomUUID().toString());
    }

    @Transactional
    public UserResponse signup(SignupRequest request) {
        if (userRepository.existsByEmailAndDeletedAtIsNull(request.email())) {
            throw new BusinessException(ErrorCode.DUPLICATE_EMAIL);
        }

        User user = User.create(
                request.email(),
                passwordEncoder.encode(request.password()),
                request.nickname());

        return UserResponse.from(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmailAndDeletedAtIsNull(request.email())
                .orElse(null);

        // 이메일이 없어도 해시 비교를 수행해 응답 시간 차이로 가입 여부가 드러나지 않게 한다.
        String storedHash = (user != null) ? user.getPassword() : dummyHash;
        boolean matched = passwordEncoder.matches(request.password(), storedHash);

        if (user == null || !matched) {
            throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
        }

        var issued = tokenProvider.issue(user.getId());
        long expiresInSec = Duration.between(Instant.now(), issued.expiresAt()).toSeconds();

        return LoginResponse.of(issued.value(), expiresInSec, UserResponse.from(user));
    }

    /**
     * 토큰을 무효 목록에 올리고, 이 기기로 더는 알림이 가지 않게 한다.
     * fcmToken을 같이 보내지 않으면 기기 등록이 남아, 같은 폰에 다른 계정이 로그인해도
     * 이전 사용자의 알림이 계속 도착한다. 앱은 로그아웃 시 반드시 함께 보내야 한다.
     */
    @Transactional
    public void logout(Long userId, Claims claims, String fcmToken) {
        revocationService.revoke(claims.getId(), claims.getExpiration().toInstant());
        deviceService.unregister(userId, fcmToken);
    }

    @Transactional
    public void withdraw(Long userId, Claims claims) {
        User user = userRepository.findByIdAndDeletedAtIsNull(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "이미 탈퇴했거나 존재하지 않는 회원입니다."));

        user.withdraw();
        revocationService.revoke(claims.getId(), claims.getExpiration().toInstant());
        deviceService.unregisterAll(userId);
    }
}
