package org.exaple.breath_care.user.social;

import org.exaple.breath_care.user.AuthProvider;

/**
 * 검증을 통과한 소셜 계정 정보.
 *
 * @param provider   어느 소셜 로그인인지
 * @param providerId 제공자가 매긴 고유 식별자. <b>이메일이 아니라 이 값이 계정의 열쇠다.</b>
 *                   사용자가 구글 계정의 이메일을 바꿔도 이 값은 그대로다
 * @param email      계정 이메일
 * @param nickname   표시 이름. 없을 수 있다
 */
public record SocialAccount(
        AuthProvider provider,
        String providerId,
        String email,
        String nickname
) {
}
