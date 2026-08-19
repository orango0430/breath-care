package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;

/**
 * 신호처리 결과.
 *
 * <p>HRV를 두 지표로 낸다. 둘 다 같은 RR 간격 배열에서 나오므로 추가 비용이 없다.
 *
 * @param hr      분당 심박수. RR 간격의 평균에서 나온다. 품질이 POOR이면 의미 없다
 * @param hrv     RMSSD(ms). <b>화면에 "HRV"로 보여주는 값이다.</b> 품질이 낮으면 null
 * @param hrvSdnn SDNN(ms). 컨디션 지수의 입력이다. 품질이 낮으면 null
 * @param quality 품질 게이트 판정
 */
public record SignalResult(Double hr, Double hrv, Double hrvSdnn, MeasurementQuality quality) {

    public static SignalResult poor() {
        return new SignalResult(null, null, null, MeasurementQuality.POOR);
    }

    public boolean isUsable() {
        return quality != MeasurementQuality.POOR;
    }
}
