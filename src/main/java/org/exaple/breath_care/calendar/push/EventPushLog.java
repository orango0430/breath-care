package org.exaple.breath_care.calendar.push;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 발송 이력. (일정, 알림종류) 조합당 한 행만 존재하며, 유니크 제약이 중복 발송의 최종 방어선이다.
 */
@Entity
@Table(
        name = "event_push_log",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_event_push_log_event_type",
                columnNames = {"event_id", "push_type"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class EventPushLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "event_id", nullable = false)
    private Long eventId;

    @Enumerated(EnumType.STRING)
    @Column(name = "push_type", nullable = false, length = 20)
    private PushType pushType;

    @Column(nullable = false)
    private Instant sentAt;

    public EventPushLog(Long eventId, PushType pushType, Instant sentAt) {
        this.eventId = eventId;
        this.pushType = pushType;
        this.sentAt = sentAt;
    }
}
