package org.exaple.breath_care.measurement;

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

/**
 * 한 번의 측정 결과. 원시 파형은 조회할 때마다 딸려오지 않도록 {@link MeasurementSignal}에 따로 둔다.
 */
@Entity
@Table(name = "measurement")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Measurement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    /** 분당 심박수 */
    @Column(nullable = false)
    private Double hr;

    /** RMSSD(ms). 품질이 낮으면 계산하지 않고 비워 둔다. */
    private Double hrv;

    /**
     * 스트레스 지수 0~100. <b>높을수록 긴장도가 높다.</b>
     * 개인 baseline과 비교해 산출하므로, baseline이 쌓이기 전에는 비어 있다.
     */
    private Double stressScore;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private MeasurementQuality quality;

    @Column(nullable = false)
    private Instant measuredAt;

    private Measurement(Long userId, Double hr, Double hrv, Double stressScore,
                        MeasurementQuality quality, Instant measuredAt) {
        this.userId = userId;
        this.hr = hr;
        this.hrv = hrv;
        this.stressScore = stressScore;
        this.quality = quality;
        this.measuredAt = measuredAt;
    }

    public static Measurement create(Long userId, Double hr, Double hrv, Double stressScore,
                                     MeasurementQuality quality, Instant measuredAt) {
        return new Measurement(userId, hr, hrv, stressScore, quality, measuredAt);
    }
}
