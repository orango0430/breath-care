package org.exaple.breath_care.session;

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
import org.exaple.breath_care.breathing.BreathingPreset;

import java.time.Instant;

/**
 * 호흡 세션 한 번. 전 측정과 후 측정을 묶어 "얼마나 좋아졌는지"를 남기는 것이 목적이다.
 *
 * <p>세션이 끝나기 전에는 후 측정이 비어 있다. 캘린더 일정에서 시작한 경우 그 일정을 가리킨다.
 */
@Entity
@Table(name = "breathing_session")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class BreathingSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    /** 사용한 호흡법. 추천 알고리즘이 붙기 전에는 비어 있을 수 있다. */
    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private BreathingPreset preset;

    @Column(nullable = false)
    private Long preMeasurementId;

    /** 세션을 마치고 재측정하면 채워진다. */
    private Long postMeasurementId;

    /** 이 세션을 유발한 일정. 없으면 사용자가 직접 시작한 것이다. */
    private Long calendarEventId;

    @Column(nullable = false)
    private Instant startedAt;

    private Instant endedAt;

    private BreathingSession(Long userId, BreathingPreset preset, Long preMeasurementId, Long calendarEventId) {
        this.userId = userId;
        this.preset = preset;
        this.preMeasurementId = preMeasurementId;
        this.calendarEventId = calendarEventId;
        this.startedAt = Instant.now();
    }

    public static BreathingSession start(Long userId, BreathingPreset preset,
                                         Long preMeasurementId, Long calendarEventId) {
        return new BreathingSession(userId, preset, preMeasurementId, calendarEventId);
    }

    public boolean isCompleted() {
        return postMeasurementId != null;
    }

    public void complete(Long postMeasurementId) {
        this.postMeasurementId = postMeasurementId;
        this.endedAt = Instant.now();
    }
}
