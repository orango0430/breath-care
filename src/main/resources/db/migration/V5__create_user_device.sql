CREATE TABLE user_device (
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    user_id    BIGINT       NOT NULL,
    fcm_token  VARCHAR(512) NOT NULL,
    platform   VARCHAR(10)  NOT NULL COMMENT 'ANDROID | IOS',
    created_at DATETIME(6)  NOT NULL,
    updated_at DATETIME(6)  NOT NULL,
    PRIMARY KEY (id),
    -- 토큰 하나 = 앱 설치 하나. 다른 계정이 같은 기기에 로그인하면 소유자만 바뀌어야 한다.
    UNIQUE KEY uk_user_device_fcm_token (fcm_token),
    KEY idx_user_device_user (user_id),
    CONSTRAINT fk_user_device_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
