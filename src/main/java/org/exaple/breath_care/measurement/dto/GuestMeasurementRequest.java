package org.exaple.breath_care.measurement.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 비회원 측정 요청. 계산만 하고 <b>서버에 아무것도 저장하지 않는다.</b>
 *
 * <p>회원 요청과 필드가 같다. 컨디션 지수가 이번 측정의 HRV만으로 나오기 때문에
 * 과거 이력을 실어 보낼 필요가 없다. (스트레스 지수를 쓰던 때는 개인 기준선을 만들려고
 * {@code recentHrs}로 과거 심박수를 받았다. V14에서 지표를 바꾸며 함께 걷어냈다.)
 *
 * @param samples     카메라 프레임의 밝기 평균값. 60초·30fps면 약 1800개
 * @param fps         초당 프레임 수
 * @param durationSec 측정 시간(초)
 */
public record GuestMeasurementRequest(

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
