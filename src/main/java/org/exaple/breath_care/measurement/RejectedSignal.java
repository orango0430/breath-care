package org.exaple.breath_care.measurement;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 품질 게이트에 걸려 거부된 파형.
 *
 * <p>성공한 측정만 남기면 알고리즘을 고칠 근거가 생기지 않는다. 고쳐야 할 대상은 언제나
 * 실패한 쪽이기 때문이다. {@code PpgCalibrationTest}가 이 데이터를 받아 돌린다.
 */
@Entity
@Table(name = "rejected_signal")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RejectedSignal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 비회원 측정이면 비어 있다. */
    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false)
    private Integer fps;

    @Column(nullable = false)
    private Integer durationSec;

    /** samples를 파싱하지 않고도 쓸 만한 파형인지 거를 수 있게 따로 둔다. */
    @Column(nullable = false)
    private Integer sampleCount;

    /** 어느 게이트에 걸렸는지. 재현할 때 무엇을 봐야 하는지 알려준다. */
    @Column(nullable = false, length = 40)
    private String reason;

    /** MEDIUMTEXT로 잡히도록 길이를 명시한다. 이유는 {@link MeasurementSignal} 주석 참고. */
    @Column(nullable = false, length = 16_777_215)
    private String samples;

    @Column(nullable = false)
    private Instant createdAt;

    public RejectedSignal(Long userId, Integer fps, Integer durationSec,
                          Integer sampleCount, String reason, String samples) {
        this.userId = userId;
        this.fps = fps;
        this.durationSec = durationSec;
        this.sampleCount = sampleCount;
        this.reason = reason;
        this.samples = samples;
        this.createdAt = Instant.now();
    }
}
