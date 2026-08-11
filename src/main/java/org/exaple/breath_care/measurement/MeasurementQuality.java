package org.exaple.breath_care.measurement;

/**
 * 신호 품질. 명세서 5-1의 품질 게이트.
 * 나쁜 데이터로 계산하지 않고 재측정을 요구하기 위한 값이다.
 */
public enum MeasurementQuality {

    /** 그대로 써도 되는 신호 */
    GOOD,
    /** HR은 믿을 만하지만 HRV는 신뢰하기 어려움 */
    FAIR,
    /** 계산하지 않고 재측정을 요구한다 */
    POOR
}
