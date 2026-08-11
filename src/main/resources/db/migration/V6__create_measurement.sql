CREATE TABLE measurement (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    user_id         BIGINT      NOT NULL,
    hr              DOUBLE      NOT NULL COMMENT '분당 심박수',
    hrv             DOUBLE      NULL COMMENT 'RMSSD(ms). 품질이 낮으면 비어 있음',
    condition_score DOUBLE      NULL COMMENT '0~100, 높을수록 좋음. baseline 전에는 비어 있음',
    quality         VARCHAR(10) NOT NULL COMMENT 'GOOD | FAIR | POOR',
    measured_at     DATETIME(6) NOT NULL COMMENT 'UTC',
    PRIMARY KEY (id),
    -- 이력 조회와 주간 통계가 모두 (내 것) + (기간) 조건이라 이 순서가 그대로 쓰인다.
    KEY idx_measurement_user_measured (user_id, measured_at),
    CONSTRAINT fk_measurement_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- 원시 파형. 알고리즘 상수를 바꾼 뒤 과거 측정을 재계산해 검증하기 위해 남긴다.
-- 목록 조회에 딸려오지 않도록 본 테이블과 분리했다.
CREATE TABLE measurement_signal (
    measurement_id BIGINT   NOT NULL,
    fps            INT      NOT NULL,
    duration_sec   INT      NOT NULL,
    samples        MEDIUMTEXT NOT NULL COMMENT '쉼표로 이어 붙인 빨강 채널 평균값(약 16MB까지)',
    PRIMARY KEY (measurement_id),
    CONSTRAINT fk_measurement_signal_measurement
        FOREIGN KEY (measurement_id) REFERENCES measurement (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
