-- 화면에 노출할 지표를 컨디션 지수(높을수록 좋음)에서 스트레스 지수(높을수록 긴장)로 확정했다.
-- 아직 값이 채워지지 않는 컬럼이라 데이터 변환은 필요 없다.
ALTER TABLE measurement
    CHANGE COLUMN condition_score stress_score DOUBLE NULL
        COMMENT '0~100, 높을수록 긴장도가 높음. baseline 전에는 비어 있음';
