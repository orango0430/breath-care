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

    @Column(nullable = false)
    private Instant createdAt;

    private CalendarEvent(Long userId, String title, EventType eventType, Instant startAt) {
        this.userId = userId;
        this.title = title;
        this.eventType = eventType;
        this.startAt = startAt;
        this.createdAt = Instant.now();
    }

    public static CalendarEvent create(Long userId, String title, EventType eventType, Instant startAt) {
        return new CalendarEvent(userId, title, eventType, startAt);
    }

    public void update(String title, EventType eventType, Instant startAt) {
        this.title = title;
        this.eventType = eventType;
        this.startAt = startAt;
    }
}
