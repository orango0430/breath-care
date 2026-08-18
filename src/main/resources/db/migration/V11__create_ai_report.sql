CREATE TABLE ai_report (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    user_id      BIGINT       NOT NULL,
    -- 집계 구간. 한국 시간 기준 날짜다 (DayRange.ZONE)
    period_start DATE         NOT NULL,
    period_end   DATE         NOT NULL,
    summary      VARCHAR(500) NOT NULL COMMENT '한두 문장 요약',
    insights     TEXT         NOT NULL COMMENT 'JSON 배열. 관찰된 패턴',
    advice       TEXT         NOT NULL COMMENT 'JSON 배열. 실행 제안',
    model        VARCHAR(50)  NOT NULL COMMENT '생성에 쓴 모델. 나중에 품질 비교용',
    generated_at DATETIME(6)  NOT NULL,
    PRIMARY KEY (id),
    -- 한 사용자의 한 기간에 리포트는 하나뿐이다.
    -- 이 유니크 제약이 캐시의 근거다. 이미 있으면 Gemini를 부르지 않고 저장된 걸 돌려준다.
    UNIQUE KEY ux_ai_report_user_period (user_id, period_start),
    CONSTRAINT fk_ai_report_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
