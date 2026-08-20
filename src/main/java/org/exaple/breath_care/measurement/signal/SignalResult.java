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
 * @param note    어디서 걸렸는지. 통과했으면 비어 있다. 아래 설명 참고
 */
public record SignalResult(Double hr, Double hrv, Double hrvSdnn,
                           MeasurementQuality quality, String note) {

    /**
     * 거부 사유를 붙여서 만든다.
     *
     * <p>사유를 남기는 이유는, 이 클래스가 "못 쓰겠다"고만 답하던 동안 실기기에서 왜
     * 떨어지는지 알 방법이 전혀 없었기 때문이다. 관류가 모자란 것과 피크를 못 찾은 것과
     * 간격이 튄 것은 고칠 곳이 서로 다른데, 밖에서 보면 똑같이 POOR 하나였다.
     *
     * @param note 사람이 읽을 짧은 사유. 숫자를 같이 담는다
     */
    public static SignalResult poor(String note) {
        return new SignalResult(null, null, null, MeasurementQuality.POOR, note);
    }

    public boolean isUsable() {
        return quality != MeasurementQuality.POOR;
    }
}
