CREATE TABLE users (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    email       VARCHAR(255) NOT NULL,
    password    VARCHAR(60)  NOT NULL COMMENT 'BCrypt 해시(고정 60자)',
    nickname    VARCHAR(50)  NULL,
    created_at  DATETIME(6)  NOT NULL,
    deleted_at  DATETIME(6)  NULL COMMENT '탈퇴 시각. NULL이 아니면 탈퇴 회원',
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- 로그아웃/탈퇴 시 아직 만료되지 않은 액세스 토큰을 무효화하기 위한 목록.
-- 만료된 행은 스케줄러가 주기적으로 지운다.
CREATE TABLE revoked_token (
    jti        VARCHAR(36) NOT NULL COMMENT 'JWT ID',
    expires_at DATETIME(6) NOT NULL,
    PRIMARY KEY (jti),
    KEY idx_revoked_token_expires_at (expires_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
