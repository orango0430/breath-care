package org.exaple.breath_care.user.social;

/**
 * 앱이 보내온 소셜 로그인 토큰을 검증한다.
 *
 * <p>검증 방식을 인터페이스로 갈라 둔 이유는, 이 자리가 바뀔 여지가 크기 때문이다.
 * 지금은 Firebase를 거치지만 구글을 직접 검증하는 방식으로 옮겨도
 * 계정 연결·발급 로직은 그대로 둘 수 있다.
 */
public interface SocialTokenVerifier {

    /**
     * @param idToken 앱이 소셜 로그인 후 받아온 ID 토큰
     * @return 검증된 계정 정보
     * @throws org.exaple.breath_care.global.exception.BusinessException 토큰이 유효하지 않거나 검증기를 쓸 수 없을 때
     */
    SocialAccount verify(String idToken);
}
