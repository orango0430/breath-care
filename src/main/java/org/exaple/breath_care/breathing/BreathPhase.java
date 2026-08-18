package org.exaple.breath_care.breathing;

/**
 * 호흡 한 구간의 성격. 앱은 이 값으로 애니메이션 방향을 정한다
 * (들이쉬면 원이 커지고, 멈추면 유지, 내쉬면 작아진다).
 */
public enum BreathPhase {

    INHALE,
    HOLD,
    EXHALE
}
