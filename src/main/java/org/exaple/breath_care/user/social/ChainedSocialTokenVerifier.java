package org.exaple.breath_care.user.social;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

/**
 * 구글 토큰을 먼저 보고, 아니면 Firebase 토큰으로 본다.
 *
 * <p>두 가지를 다 받는 이유는 앱 버전이 섞이기 때문이다. 새 앱은 구글 로그인에서 받은
 * 토큰을 그대로 보내고, 이미 배포된 앱은 그것을 Firebase 토큰으로 바꿔서 보낸다.
 * 서버가 둘 다 알아보면 앱을 강제로 업데이트시키지 않아도 된다.
 *
 * <p>구글 쪽을 먼저 보는 이유는 단계가 적어서다. 구글 검증은 Firebase 프로젝트 설정이나
 * 서비스 계정 상태와 무관하게 동작하므로, 그쪽이 어긋나 있어도 로그인은 살아 있다.
 */
@Component
public class ChainedSocialTokenVerifier implements SocialTokenVerifier {

    private static final Logger log =
            LoggerFactory.getLogger(ChainedSocialTokenVerifier.class);

    private final GoogleTokenVerifier googleVerifier;

    /** Firebase 키 없이 띄운 서버에는 아예 없다. 그래도 구글 로그인은 되어야 한다. */
    private final ObjectProvider<FirebaseTokenVerifier> firebaseVerifier;

    public ChainedSocialTokenVerifier(GoogleTokenVerifier googleVerifier,
                                      ObjectProvider<FirebaseTokenVerifier> firebaseVerifier) {
        this.googleVerifier = googleVerifier;
        this.firebaseVerifier = firebaseVerifier;
    }

    @Override
    public SocialAccount verify(String idToken) {
        SocialAccount account = googleVerifier.verifyOrNull(idToken);
        if (account != null) {
            return account;
        }

        FirebaseTokenVerifier firebase = firebaseVerifier.getIfAvailable();
        if (firebase != null) {
            account = firebase.verifyOrNull(idToken);
            if (account != null) {
                return account;
            }
        }

        if (!googleVerifier.isConfigured() && firebase == null) {
            log.warn("소셜 로그인 검증기가 하나도 설정돼 있지 않습니다.");
            throw new BusinessException(ErrorCode.SOCIAL_LOGIN_UNAVAILABLE);
        }

        // 어느 쪽으로도 읽히지 않았다. 토큰 내용은 남기지 않고 길이만 남긴다 —
        // 전송 중 잘렸는지(짧음) 아예 다른 값인지(형식 이상) 구분하는 데 쓴다.
        log.warn("소셜 토큰을 어느 방식으로도 검증하지 못했습니다. 토큰 모양={}", shapeOf(idToken));
        throw new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN);
    }

    /**
     * 토큰의 "모양"만 남긴다. 내용은 찍지 않는다.
     *
     * <p>정상적인 ID 토큰은 점으로 나뉜 세 토막이고 서명 토막이 342자다. 토막 수나
     * 길이가 어긋나면 검증 이전에 값 자체가 망가져서 온 것이다.
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
}
