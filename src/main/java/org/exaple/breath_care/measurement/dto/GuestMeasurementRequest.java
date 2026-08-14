package org.exaple.breath_care.measurement.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 비회원 측정 요청. 계산만 하고 <b>서버에 아무것도 저장하지 않는다.</b>
 *
 * <p>회원은 서버가 측정 이력을 갖고 있어 기준선을 스스로 만들 수 있지만,
 * 비회원의 이력은 폰에만 있다. 그래서 과거 심박수를 요청에 실어 보낸다.
 * 계산 코드는 회원과 완전히 같은 것을 쓴다.
 *
 * @param samples     카메라 프레임의 밝기 평균값. 60초·30fps면 약 1800개
 * @param fps         초당 프레임 수
 * @param durationSec 측정 시간(초)
 * @param recentHrs   과거 측정의 심박수를 <b>최신순</b>으로. 이번 측정은 넣지 않는다.
 *                    5개 미만이면 기준선이 없어 스트레스 지수는 null로 나간다
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
        Integer durationSec,

        // 인증 없이 열린 창구라 값의 범위를 막아 둔다. 말이 안 되는 심박수가 섞이면
        // 기준선이 통째로 망가져 점수가 엉뚱하게 나온다.
        @Size(max = 100, message = "과거 심박수가 너무 많습니다.")
        List<@NotNull @DecimalMin(value = "20.0") @DecimalMax(value = "250.0") Double> recentHrs
) {
}
