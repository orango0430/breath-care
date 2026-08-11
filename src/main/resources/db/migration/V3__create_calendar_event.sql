CREATE TABLE calendar_event (
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    user_id    BIGINT       NOT NULL,
    title      VARCHAR(255) NOT NULL,
    event_type VARCHAR(20)  NULL COMMENT '사용자가 고른 일정 종류. 폰 캘린더 동기화 건은 비어 있을 수 있다',
    start_at   DATETIME(6)  NOT NULL COMMENT 'UTC',
    created_at DATETIME(6)  NOT NULL,
    PRIMARY KEY (id),
    -- 조회는 항상 (내 것) + (기간) 조건이라 이 순서의 복합 인덱스가 그대로 쓰인다.
    KEY idx_calendar_event_user_start (user_id, start_at),
    CONSTRAINT fk_calendar_event_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
