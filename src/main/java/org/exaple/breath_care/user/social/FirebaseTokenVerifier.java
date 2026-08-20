package org.exaple.breath_care.user.social;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.user.AuthProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Firebase가 발급한 ID 토큰을 검증한다. 서명·만료·발급자 확인을 SDK가 대신 해 준다.
 *
 * <p>앱이 구글 토큰을 직접 보내는 쪽으로 옮겨 갔으므로 이 경로는 이제 보조다.
 * 예전 버전 앱이 아직 Firebase 토큰을 보내고 있어 남겨 둔다.
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(FirebaseTokenVerifier.class);

    private final FirebaseAuth firebaseAuth;

    /**
     * Firebase 토큰이면 계정 정보를, 아니면 null을 준다.
     *
     * <p>null은 "이 토큰은 Firebase 것이 아니다"라는 뜻이다. 다음 검증기로 넘어갈 수
     * 있도록 예외 대신 null로 답한다. 다만 검증은 통과했는데 이메일이 없는 경우는
     * 다음으로 넘겨도 결과가 같으므로 여기서 끝낸다.
     */
    public SocialAccount verifyOrNull(String idToken) {
        FirebaseToken token;
        try {
            token = firebaseAuth.verifyIdToken(idToken);
        } catch (FirebaseAuthException e) {
            // 만료·위조·다른 프로젝트의 토큰이 모두 여기로 온다.
            // 사용자에게는 어느 쪽인지 알려주지 않는다. 토큰을 맞춰 보는 힌트가 되기 때문이다.
            log.debug("Firebase 토큰 검증 불가 [{}]: {}", e.getAuthErrorCode(), e.getMessage());
            return null;
        }

        if (token.getEmail() == null || token.getEmail().isBlank()) {
            // 이메일 없는 제공자(전화번호 로그인 등)는 아직 다루지 않는다.
            throw new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN,
                    "이메일을 제공하지 않는 계정으로는 로그인할 수 없어요.");
        }

        return new SocialAccount(
                providerOf(token),
                token.getUid(),
                token.getEmail(),
                token.getName());
    }

    /**
     * 어느 제공자로 로그인했는지. Firebase는 여러 제공자를 한 계정에 묶을 수 있어
     * 토큰 안에 sign_in_provider로 들어온다.
     */
    private AuthProvider providerOf(FirebaseToken token) {
        Object firebase = token.getClaims().get("firebase");
        if (firebase instanceof Map<?, ?> claims
                && "google.com".equals(claims.get("sign_in_provider"))) {
            return AuthProvider.GOOGLE;
        }
        return AuthProvider.GOOGLE;
    }
}
