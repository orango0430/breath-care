package org.exaple.breath_care.measurement.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 측정 결과 전송. 앱은 계산하지 않고 원시 파형만 보낸다.
 *
 * @param samples     카메라 프레임의 빨강 채널 평균값. 60초·30fps면 약 1800개
 * @param fps         초당 프레임 수
 * @param durationSec 측정 시간(초)
 */
public record MeasurementRequest(

        @NotEmpty(message = "신호 데이터는 필수입니다.")
        @Size(max = 30000, message = "신호 데이터가 너무 깁니다.")
        List<@NotNull Double> samples,

        @NotNull(message = "fps는 필수입니다.")
        @Min(value = 10, message = "fps는 10 이상이어야 합니다.")
        @Max(value = 240, message = "fps는 240 이하여야 합니다.")
        Integer fps,

        @NotNull(message = "측정 시간은 필수입니다.")
        @Min(value = 10, message = "측정 시간은 10초 이상이어야 합니다.")
        @Max(value = 300, message = "측정 시간은 300초 이하여야 합니다.")
        Integer durationSec
) {
}
