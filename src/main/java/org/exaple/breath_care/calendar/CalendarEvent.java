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

    /**
     * 시안의 "+"로 직접 만든 카테고리 이름. 없으면 종류의 기본 이름을 쓴다.
     *
     * <p><b>이름만 바꾼다. 호흡 추천은 계속 {@link #eventType}이 정한다.</b>
     * 자유 문자열로는 어떤 호흡을 권할지 판단할 근거가 없기 때문이다.
     */
    @Column(length = 20)
    private String customCategory;

    /** 일정 시각. 앱에서 오프셋 포함 ISO-8601로 보내고 서버는 UTC로 저장한다. */
    @Column(nullable = false)
    private Instant startAt;

    /**
     * 사용자가 완료 처리한 시각. null이면 아직 안 끝난 일정이다.
     *
     * <p>boolean이 아니라 시각인 이유: "언제 끝냈는지"를 알면 나중에 통계에 쓸 수 있고,
     * 지금도 시각 없이 참/거짓만 남기는 것보다 잃는 게 없다.
     */
    private Instant completedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private EventSource source;

    /** 폰 캘린더가 매긴 일정 id. 직접 입력한 일정은 비어 있다. */
    @Column(length = 255)
    private String externalId;

    @Column(nullable = false)
    private Instant createdAt;

    private CalendarEvent(Long userId, String title, EventType eventType, String customCategory,
                          Instant startAt, EventSource source, String externalId) {
        this.userId = userId;
        this.title = title;
        this.eventType = eventType;
        this.customCategory = customCategory;
        this.startAt = startAt;
        this.source = source;
        this.externalId = externalId;
        this.createdAt = Instant.now();
    }

    public static CalendarEvent create(Long userId, String title, EventType eventType,
                                       String customCategory, Instant startAt) {
        return new CalendarEvent(userId, title, eventType, customCategory, startAt, EventSource.MANUAL, null);
    }

    /**
     * 폰 캘린더에서 들어온 일정. 종류는 비워 둔다.
     * 폰 일정에는 종류 정보가 없고, 제목으로 추측하면 틀리기 쉽다. 사용자가 앱에서 고르면 채워진다.
     */
    public static CalendarEvent fromPhone(Long userId, String title, Instant startAt, String externalId) {
        return new CalendarEvent(userId, title, null, null, startAt, EventSource.PHONE, externalId);
    }

    /** 완료 처리를 켜고 끈다. 되돌릴 수 있어야 해서 해제도 같은 메서드로 받는다. */
    public void markCompleted(boolean completed) {
        this.completedAt = completed ? Instant.now() : null;
    }

    public boolean isCompleted() {
        return completedAt != null;
    }

    public void update(String title, EventType eventType, String customCategory, Instant startAt) {
        this.title = title;
        this.eventType = eventType;
        this.customCategory = customCategory;
        this.startAt = startAt;
    }

    /**
     * 화면·알림에 쓸 카테고리 이름. 직접 만든 이름이 있으면 그것, 없으면 종류의 기본 이름.
     * 종류까지 비어 있으면(폰 캘린더 동기화 건) "일정"이다.
     */
    public String displayCategory() {
        if (customCategory != null && !customCategory.isBlank()) {
            return customCategory;
        }
        return (eventType != null) ? eventType.getLabel() : EventType.ETC.getLabel();
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
