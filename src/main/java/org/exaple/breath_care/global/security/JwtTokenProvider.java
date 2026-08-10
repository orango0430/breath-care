package org.exaple.breath_care.global.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    private final SecretKey key;
    private final long validityMs;

    public JwtTokenProvider(JwtProperties properties) {
        // 32바이트 미만이면 여기서 예외가 나며 부팅이 실패한다. (약한 키로 조용히 뜨는 것보다 낫다)
        this.key = Keys.hmacShaKeyFor(properties.secret().getBytes(StandardCharsets.UTF_8));
        this.validityMs = properties.accessTokenValidityMs();
    }

    public IssuedToken issue(Long userId) {
        Instant now = Instant.now();
        Instant expiresAt = now.plusMillis(validityMs);
        String jti = UUID.randomUUID().toString();

        String token = Jwts.builder()
                .id(jti)
                .subject(String.valueOf(userId))
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt))
                .signWith(key)
                .compact();

        return new IssuedToken(token, jti, expiresAt);
    }

    /** 서명·만료가 유효하면 claims를 반환한다. 유효하지 않으면 비어 있다. */
    public Optional<Claims> parse(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return Optional.of(claims);
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    public record IssuedToken(String value, String jti, Instant expiresAt) {
    }
}
