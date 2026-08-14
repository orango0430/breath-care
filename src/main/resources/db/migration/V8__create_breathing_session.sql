CREATE TABLE breathing_session (
    id                  BIGINT      NOT NULL AUTO_INCREMENT,
    user_id             BIGINT      NOT NULL,
    preset              VARCHAR(30) NULL COMMENT 'BOX | FOUR_SEVEN_EIGHT | EXHALE_EXTENDED',
    pre_measurement_id  BIGINT      NOT NULL COMMENT '세션 전 측정',
    post_measurement_id BIGINT      NULL COMMENT '세션 후 재측정. 종료 전에는 비어 있음',
    calendar_event_id   BIGINT      NULL COMMENT '알림에서 시작한 경우 그 일정',
    started_at          DATETIME(6) NOT NULL,
    ended_at            DATETIME(6) NULL,
    PRIMARY KEY (id),
    KEY idx_breathing_session_user_started (user_id, started_at),
    -- 일정별 세션을 찾을 때 쓴다 (시안의 "일정마다 점수 표시")
    KEY idx_breathing_session_event (calendar_event_id),
    CONSTRAINT fk_breathing_session_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_breathing_session_pre FOREIGN KEY (pre_measurement_id) REFERENCES measurement (id),
    CONSTRAINT fk_breathing_session_post FOREIGN KEY (post_measurement_id) REFERENCES measurement (id),
    -- 일정을 지워도 세션 기록은 남긴다. 통계에서 빠지면 안 되기 때문이다.
    CONSTRAINT fk_breathing_session_event FOREIGN KEY (calendar_event_id)
        REFERENCES calendar_event (id) ON DELETE SET NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
