package org.exaple.breath_care.global.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 로그아웃·탈퇴로 무효화된 액세스 토큰.
 * JWT는 그 자체로는 취소가 안 되므로, 만료 전까지 이 목록으로 막는다.
 */
@Entity
@Table(name = "revoked_token")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RevokedToken {

    @Id
    @Column(length = 36)
    private String jti;

    @Column(nullable = false)
    private Instant expiresAt;

    public RevokedToken(String jti, Instant expiresAt) {
        this.jti = jti;
        this.expiresAt = expiresAt;
    }
}
