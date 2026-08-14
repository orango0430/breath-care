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

/**
 * Firebase가 발급한 ID 토큰을 검증한다. 서명·만료·발급자 확인을 SDK가 대신 해 준다.
 *
 * <p>앱은 구글 로그인 결과를 Firebase에 넘겨 ID 토큰을 받고, 그 토큰만 서버로 보낸다.
 * 서버가 구글과 직접 주고받는 것이 없으므로 클라이언트 ID 설정이 필요 없다.
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseSocialTokenVerifier implements SocialTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(FirebaseSocialTokenVerifier.class);

    private final FirebaseAuth firebaseAuth;

    @Override
    public SocialAccount verify(String idToken) {
        FirebaseToken token = decode(idToken);

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

    private FirebaseToken decode(String idToken) {
        try {
            return firebaseAuth.verifyIdToken(idToken);
        } catch (FirebaseAuthException e) {
            // 만료·위조·다른 프로젝트의 토큰이 모두 여기로 온다.
            // 어느 쪽인지 알려주면 토큰을 맞춰 보는 데 힌트가 되므로 구분하지 않는다.
            log.debug("소셜 토큰 검증 실패: {}", e.getAuthErrorCode(), e);
            throw new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN);
        }
    }

    /**
     * 어느 제공자로 로그인했는지. Firebase는 여러 제공자를 한 계정에 묶을 수 있어
     * 토큰 안에 sign_in_provider로 들어온다.
     */
    private AuthProvider providerOf(FirebaseToken token) {
        Object firebase = token.getClaims().get("firebase");
        if (firebase instanceof java.util.Map<?, ?> claims
                && "google.com".equals(claims.get("sign_in_provider"))) {
            return AuthProvider.GOOGLE;
        }

        throw new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN,
                "지원하지 않는 로그인 방식이에요.");
    }
}
