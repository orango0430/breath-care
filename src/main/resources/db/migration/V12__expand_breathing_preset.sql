-- 호흡법 프리셋을 3종에서 8종으로 늘린다. (프론트 구현 8종과 맞춤)
--
-- EXHALE_EXTENDED는 없어지고 RELAX_FOUR_SIX(4-6 릴랙스)가 그 자리를 대신한다.
-- 둘 다 "멈춤 없이 날숨을 길게"라 성격이 같다.
-- 이 UPDATE가 없으면 기존 세션을 읽을 때 enum 변환에서 터진다.
UPDATE breathing_session
SET preset = 'RELAX_FOUR_SIX'
WHERE preset = 'EXHALE_EXTENDED';

-- 컬럼 주석이 3종만 적고 있어 실제와 어긋난다. 길이(30)는 가장 긴 이름
-- PHYSIOLOGICAL_SIGH(18)도 들어가므로 그대로 둔다.
ALTER TABLE breathing_session
    MODIFY COLUMN preset VARCHAR(30) NULL COMMENT '호흡법 8종. BreathingPreset enum 참고';
