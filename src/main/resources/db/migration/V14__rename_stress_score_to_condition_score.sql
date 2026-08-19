-- 화면에 노출할 지표를 스트레스 지수에서 컨디션 지수로 되돌린다. V7의 반대다.
--
-- V7에서 컨디션 -> 스트레스로 바꿨던 이유는 "긴장도"가 앱 성격에 맞는다고 봤기 때문인데,
-- 산출 방식이 개인 기준선(최근 20회 심박수) 대비 z-score라 측정 5회를 채우기 전에는
-- 계속 null이었다. 행사에서 한 번씩 측정하는 사람에게는 영영 숫자가 안 나온다.
--
-- 컨디션 지수는 HRV 하나로 바로 계산되어 첫 측정부터 값이 나온다.
-- 의미가 뒤집히므로(높을수록 긴장 -> 높을수록 좋음) 값을 그대로 옮기면 안 되는데,
-- 산출 로직이 바뀌면서 기존 값은 어차피 못 쓴다. 아직 전부 null이라 변환할 것도 없다.
ALTER TABLE measurement
    CHANGE COLUMN stress_score condition_score DOUBLE NULL
        COMMENT '0~100, 높을수록 좋음. 품질이 낮아 HRV가 없으면 비어 있음';

-- 컨디션 지수의 입력이 되는 HRV다. hrv 컬럼(RMSSD)과 지표가 다르므로 따로 둔다.
--
--   hrv      = RMSSD. 인접 RR 간격의 차이. 화면에 "HRV"로 보여주는 값이고,
--              소비자 웨어러블(Whoop, Oura 등)이 HRV라 부르는 것과 같은 지표다.
--   hrv_sdnn = SDNN. RR 간격 전체의 표준편차. 컨디션 지수 계산에 쓴다.
--
-- 둘 다 같은 RR 간격 배열에서 나오므로 계산 비용은 사실상 같다. 어느 쪽이 사람을
-- 더 잘 가르는지는 실측 파형을 받아 보고 정한다. 그때 컨디션 지수의 입력만 바꾸면 된다.
ALTER TABLE measurement
    ADD COLUMN hrv_sdnn DOUBLE NULL COMMENT 'SDNN(ms). 컨디션 지수의 입력. 품질이 낮으면 비어 있음'
        AFTER hrv;
