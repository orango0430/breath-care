package org.exaple.breath_care.user.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 소셜 로그인.
 *
 * @param idToken 앱이 구글 로그인 후 Firebase에서 받아온 ID 토큰.
 *                <b>액세스 토큰이 아니라 ID 토큰이다.</b> 둘을 헷갈리면 검증에서 걸린다
 */
public record SocialLoginRequest(

        @NotBlank(message = "idToken은 필수입니다.")
        String idToken
) {
}
