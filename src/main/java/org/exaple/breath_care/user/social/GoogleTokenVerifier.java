package org.exaple.breath_care.user.social;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.exaple.breath_care.user.AuthProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

/**
 * 구글이 발급한 ID 토큰을 서버가 직접 검증한다.
 *
 * <p>앱이 구글 로그인에서 받은 토큰을 그대로 보내면 된다. 중간에 Firebase로 한 번
 * 바꿔 오는 경로보다 단계가 하나 적고, 그만큼 어긋날 곳도 적다. Firebase Auth의
 * 제공자 설정이나 서비스 계정 상태와도 무관해서, 그쪽이 어떻든 로그인은 된다.
 *
 * <p>서명 검증은 구글 공개키로 하며 키는 라이브러리가 캐시하고 갱신한다.
 */
@Component
public class GoogleTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifier.class);

    /** 구글이 이 두 값 중 하나를 발급자로 쓴다. 둘 다 정상이다. */
    private static final List<String> ISSUERS =
            List.of("accounts.google.com", "https://accounts.google.com");

    private final GoogleIdTokenVerifier verifier;
    private final boolean configured;

    public GoogleTokenVerifier(@Value("${google.client-ids:}") String clientIds) {
        // 앱이 serverClientId로 넘긴 웹 클라이언트가 토큰의 aud가 된다.
        // 안드로이드 클라이언트 id로 오는 경우도 있어 둘 다 받아 둔다.
        List<String> audiences = Arrays.stream(clientIds.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .toList();

        this.configured = !audiences.isEmpty();
        this.verifier = configured
                ? new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                        .setAudience(audiences)
                        .setIssuers(ISSUERS)
                        .build()
                : null;

        if (!configured) {
            log.info("google.client-ids가 비어 있어 구글 토큰 직접 검증은 꺼둡니다.");
        }
    }

    public boolean isConfigured() {
        return configured;
    }

    /**
     * 구글 토큰이면 계정 정보를, 아니면 null을 준다.
     *
     * <p>null은 "이 토큰은 구글 것이 아니다"라는 뜻이지 실패가 아니다. 호출하는 쪽이
     * 다음 검증기로 넘어갈 수 있도록 예외 대신 null로 답한다.
     */
    public SocialAccount verifyOrNull(String idToken) {
        if (!configured) {
            return null;
        }

        try {
            GoogleIdToken token = verifier.verify(idToken);
            if (token == null) {
                return null;
            }

            GoogleIdToken.Payload payload = token.getPayload();
            String email = payload.getEmail();
            if (!StringUtils.hasText(email)) {
                return null;
            }

            return new SocialAccount(
                    AuthProvider.GOOGLE,
                    payload.getSubject(),
                    email,
                    (String) payload.get("name"));
        } catch (GeneralSecurityException | IOException | IllegalArgumentException e) {
            // 서명이 안 맞거나 형식이 다르면 구글 토큰이 아니라고 보고 넘긴다.
            log.debug("구글 토큰 검증 불가: {}", e.getMessage());
            return null;
        }
    }
}
