-- 시안의 카테고리 "+" 버튼. 사용자가 직접 만든 카테고리 이름을 담는다.
--
-- 종류(event_type)를 없애고 이 컬럼으로 대체하지 않은 이유:
-- 호흡 추천이 종류를 보고 결정한다. 자유 문자열만 남기면 "동아리 공연"에 어떤 호흡을
-- 권할지 판단할 근거가 사라진다. 이름만 바꾸고 성격은 종류가 계속 쥔다.
ALTER TABLE calendar_event
    ADD COLUMN custom_category VARCHAR(20) NULL
        COMMENT '"+"로 직접 만든 카테고리 이름. 있으면 화면·알림에 종류 대신 이 이름을 쓴다'
        AFTER event_type;
