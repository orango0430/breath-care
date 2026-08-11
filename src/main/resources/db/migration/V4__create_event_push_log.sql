CREATE TABLE event_push_log (
    id        BIGINT      NOT NULL AUTO_INCREMENT,
    event_id  BIGINT      NOT NULL,
    push_type VARCHAR(20) NOT NULL COMMENT 'DAY_BEFORE(전날 21시) | BEFORE_30M(30분 전)',
    sent_at   DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    -- 중복 발송의 최종 방어선. 스케줄러가 겹쳐 돌아도 두 번 나가지 않는다.
    UNIQUE KEY uk_event_push_log_event_type (event_id, push_type),
    CONSTRAINT fk_event_push_log_event FOREIGN KEY (event_id) REFERENCES calendar_event (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
