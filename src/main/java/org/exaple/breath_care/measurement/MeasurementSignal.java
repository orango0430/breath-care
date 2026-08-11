package org.exaple.breath_care.measurement;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 측정에 쓰인 원시 파형. 알고리즘 상수를 바꾼 뒤 과거 측정을 다시 계산해 검증하기 위해 보관한다.
 * 목록 조회에는 필요 없는 데이터라 measurement 테이블과 분리했다.
 */
@Entity
@Table(name = "measurement_signal")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MeasurementSignal {

    /** measurement와 1:1. 별도 시퀀스를 두지 않고 측정 id를 그대로 쓴다. */
    @Id
    @Column(name = "measurement_id")
    private Long measurementId;

    @Column(nullable = false)
    private Integer fps;

    @Column(nullable = false)
    private Integer durationSec;

    /**
     * 쉼표로 이어 붙인 빨강 채널 평균값. 60초·30fps면 약 20KB.
     *
     * <p>@Lob 대신 길이를 명시한다. @Lob은 길이 정보가 없어 Hibernate가 tinytext(255자)를 기대하는데,
     * 마이그레이션은 그보다 큰 타입을 만들어 ddl-auto=validate에서 부팅이 실패한다.
     * 이 길이면 MySQL에서 MEDIUMTEXT(약 16MB)로 잡힌다.
     */
    @Column(nullable = false, length = 16_777_215)
    private String samples;

    public MeasurementSignal(Long measurementId, Integer fps, Integer durationSec, String samples) {
        this.measurementId = measurementId;
        this.fps = fps;
        this.durationSec = durationSec;
        this.samples = samples;
    }
}
