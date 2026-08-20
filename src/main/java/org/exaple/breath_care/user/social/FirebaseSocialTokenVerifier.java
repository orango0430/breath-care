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
            // 사용자에게는 어느 쪽인지 알려주지 않는다. 토큰을 맞춰 보는 힌트가 되기 때문이다.
            //
            // 다만 서버 로그에는 남긴다. SDK 메시지가 "Expected X but got Y" 형태로
            // 양쪽 프로젝트 id를 그대로 알려주는데, 이게 없으면 소셜 로그인이 전부
            // 실패할 때 서비스 계정이 다른 프로젝트 것인지 확인할 방법이 없다.
            // 두 id 모두 앱에 이미 들어 있는 공개 값이라 로그에 남겨도 문제없다.
            log.warn("소셜 토큰 검증 실패 [{}]: {} | 토큰 모양={}",
                    e.getAuthErrorCode(), e.getMessage(), shapeOf(idToken));
            throw new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN);
        }
    }

    /**
     * 토큰의 "모양"만 남긴다. 내용은 찍지 않는다.
     *
     * <p>서명 검증만 실패하는 경우(aud·iss·만료는 통과) 원인이 둘로 갈린다.
     * 전송 중 잘려서 서명 부분이 깨졌거나, 서명한 키를 서버가 못 찾거나.
     * 세 토막의 길이를 보면 앞쪽인지 뒤쪽인지 바로 갈린다 — 정상적인 Firebase ID
     * 토큰은 대략 900~1200자에 서명 토막이 342자다.
     */
    private String shapeOf(String idToken) {
        if (idToken == null) {
            return "null";
        }
        String[] parts = idToken.split("\\.");
        StringBuilder lengths = new StringBuilder();
        for (String part : parts) {
            if (!lengths.isEmpty()) {
                lengths.append('/');
            }
            lengths.append(part.length());
        }
        return "전체 %d자, %d토막(%s)".formatted(idToken.length(), parts.length, lengths);
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
