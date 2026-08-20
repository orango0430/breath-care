-- 품질 게이트에 걸려 거부된 원시 파형.
--
-- measurement_signal과 나눈 이유: 저쪽은 measurement 행에 딸린 1:1 데이터라 측정이
-- 성공해야만 존재한다. 그런데 알고리즘을 고칠 때 정작 필요한 건 실패한 파형이다.
-- 거부는 저장 전에 예외로 끝나므로 지금까지 실패 파형이 한 건도 남지 않았고,
-- 그래서 실기기에서 왜 떨어지는지 매번 추측으로 되짚어야 했다.
--
-- 비회원 측정도 남긴다. 그쪽이 오히려 첫 사용자의 파형이라 더 값지다. user_id는 그래서 NULL을 받는다.
CREATE TABLE rejected_signal (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    user_id      BIGINT       NULL COMMENT '비회원 측정이면 비어 있음',
    fps          INT          NOT NULL,
    duration_sec INT          NOT NULL,
    sample_count INT          NOT NULL COMMENT 'samples를 파싱하지 않고 거르려고 따로 둔다',
    reason       VARCHAR(40)  NOT NULL COMMENT '어느 게이트에 걸렸는지',
    samples      MEDIUMTEXT   NOT NULL COMMENT '쉼표로 이어 붙인 밝기 평균값',
    created_at   DATETIME(6)  NOT NULL COMMENT 'UTC',
    PRIMARY KEY (id),
    -- 캘리브레이션은 "최근 것부터 N건"으로 꺼낸다.
    KEY idx_rejected_signal_created (created_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
