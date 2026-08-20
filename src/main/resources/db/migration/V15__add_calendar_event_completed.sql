-- 일정 완료 체크. 앱의 일정 목록에서 끝난 일정에 체크 표시를 남기기 위한 것이다.
--
-- 세션(breathing_session)으로 대신하지 않은 이유:
-- 세션은 "호흡을 했다"는 기록이고, 완료는 "그 일정이 끝났다"는 뜻이라 서로 다르다.
-- 발표를 마쳤지만 호흡은 안 한 경우가 있고, 그 반대도 있다.
ALTER TABLE calendar_event
    ADD COLUMN completed_at DATETIME(6) NULL
        COMMENT '완료 처리한 시각. NULL이면 아직 안 끝난 일정'
        AFTER start_at;
