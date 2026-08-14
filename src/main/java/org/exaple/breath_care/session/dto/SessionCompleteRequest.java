package org.exaple.breath_care.session.dto;

import jakarta.validation.constraints.NotNull;

/** 세션 종료. 끝나고 다시 측정한 결과를 묶는다. */
public record SessionCompleteRequest(

        @NotNull(message = "세션 후 측정 id는 필수입니다.")
        Long postMeasurementId
) {
}
