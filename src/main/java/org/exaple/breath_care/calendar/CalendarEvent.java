package org.exaple.breath_care.calendar;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "calendar_event")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CalendarEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String title;

    /**
     * 폰 캘린더 동기화로 들어온 일정은 종류를 모를 수 있어 nullable로 둔다.
     * null이면 호흡 추천은 기본 프리셋(날숨 연장)을 쓴다.
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private EventType eventType;

    /** 일정 시각. 앱에서 오프셋 포함 ISO-8601로 보내고 서버는 UTC로 저장한다. */
    @Column(nullable = false)
    private Instant startAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private EventSource source;

    /** 폰 캘린더가 매긴 일정 id. 직접 입력한 일정은 비어 있다. */
    @Column(length = 255)
    private String externalId;

    @Column(nullable = false)
    private Instant createdAt;

    private CalendarEvent(Long userId, String title, EventType eventType, Instant startAt,
                          EventSource source, String externalId) {
        this.userId = userId;
        this.title = title;
        this.eventType = eventType;
        this.startAt = startAt;
        this.source = source;
        this.externalId = externalId;
        this.createdAt = Instant.now();
    }

    public static CalendarEvent create(Long userId, String title, EventType eventType, Instant startAt) {
        return new CalendarEvent(userId, title, eventType, startAt, EventSource.MANUAL, null);
    }

    /**
     * 폰 캘린더에서 들어온 일정. 종류는 비워 둔다.
     * 폰 일정에는 종류 정보가 없고, 제목으로 추측하면 틀리기 쉽다. 사용자가 앱에서 고르면 채워진다.
     */
    public static CalendarEvent fromPhone(Long userId, String title, Instant startAt, String externalId) {
        return new CalendarEvent(userId, title, null, startAt, EventSource.PHONE, externalId);
    }

    public void update(String title, EventType eventType, Instant startAt) {
        this.title = title;
        this.eventType = eventType;
        this.startAt = startAt;
    }

    /**
     * 폰 캘린더의 변경사항만 반영한다.
     *
     * <p><b>eventType은 건드리지 않는다.</b> 사용자가 "시험"으로 골라 둔 것을
     * 동기화할 때마다 지워 버리면 알림 문구가 계속 "일정"으로 되돌아간다.
     */
    public void syncFrom(String title, Instant startAt) {
        this.title = title;
        this.startAt = startAt;
    }
}
