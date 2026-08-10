package org.exaple.breath_care.global.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param secret               HS256 서명 키. 최소 32바이트여야 한다.
 * @param accessTokenValidityMs 액세스 토큰 유효시간(ms)
 */
@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(String secret, long accessTokenValidityMs) {
}
