-- 폰 캘린더 동기화.
-- 기존 일정은 전부 앱에서 직접 입력한 것이므로 MANUAL로 채운다.
ALTER TABLE calendar_event
    ADD COLUMN source      VARCHAR(10)  NOT NULL DEFAULT 'MANUAL' COMMENT 'MANUAL(직접 입력) | PHONE(폰 캘린더)',
    ADD COLUMN external_id VARCHAR(255) NULL COMMENT '폰 캘린더가 매긴 일정 id. 재동기화 시 같은 일정을 알아보는 열쇠';

-- 같은 폰 일정이 두 번 들어오지 않게 막는다. 이게 없으면 동기화할 때마다 일정이 불어난다.
-- MANUAL 일정은 external_id가 NULL이고, MySQL은 유니크 인덱스에서 NULL 중복을 허용한다.
CREATE UNIQUE INDEX ux_calendar_event_external ON calendar_event (user_id, external_id);
