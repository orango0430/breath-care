package org.exaple.breath_care.breathing;

/**
 * 호흡법 프리셋. 명세서 5-2에서 확정된 3종.
 * 세부 파라미터(들숨·멈춤·날숨 초)는 추천 알고리즘 구현 시 이 enum에 붙인다.
 */
public enum BreathingPreset {

    /** 4-4-4-4. 긴급 진정·집중. 발표·면접 직전 */
    BOX,
    /** 4-7-8. 깊은 이완·수면 전. 시험 전날 밤 */
    FOUR_SEVEN_EIGHT,
    /** 들숨보다 날숨을 길게. 일반·초보·빠른 진정. 기본값 */
    EXHALE_EXTENDED
}
