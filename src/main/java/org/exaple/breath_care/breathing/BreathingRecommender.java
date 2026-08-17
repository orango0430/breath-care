package org.exaple.breath_care.breathing;

import org.exaple.breath_care.calendar.EventType;
import org.exaple.breath_care.calendar.push.PushType;

/**
 * 어떤 호흡을 권할지 정한다.
 *
 * <p><b>시점이 1순위, 일정 종류가 2순위다.</b> 전날 밤에 하는 목적은 "내일 뭐가 있든 일단 자야 한다"로
 * 종류와 무관하게 같기 때문이다. 그래서 밤에는 종류를 보지 않고 4-7-8을 권한다.
 * 8종 중 날숨이 8초로 가장 길어 이완에 제일 맞다.
 *
 * <p>직전 30분은 반대다. 목적이 종류마다 갈리므로 프론트가 배정해 둔 것을 따른다.
 *
 * <pre>
 *              전날 밤 22시      30분 전
 *   발표         4-7-8         생리학적 한숨   (즉각적 심박수 강하, 주기 8.5초로 가장 빠름)
 *   시험         4-7-8         박스 호흡      (몰입·집중력)
 *   면접         4-7-8         공진 호흡      (자율신경 균형)
 *   마감·기타     4-7-8         4-6 릴랙스     (기본값)
 * </pre>
 *
 * <p>규칙이 순수 함수라 서비스가 아니라 정적 메서드다. 상태도 의존성도 없다.
 */
public final class BreathingRecommender {

    private BreathingRecommender() {
    }

    /** 전날 밤 공통. 자기 전 이완이 목적이라 종류를 가리지 않는다. */
    private static final BreathingPreset NIGHT = BreathingPreset.FOUR_SEVEN_EIGHT;

    /**
     * @param eventType 일정 종류. 폰 캘린더에서 온 일정처럼 모를 수 있어 null을 허용한다
     */
    public static BreathingPreset recommend(EventType eventType, PushType pushType) {
        if (pushType == PushType.DAY_BEFORE) {
            return NIGHT;
        }
        if (eventType == null) {
            return BreathingPreset.DEFAULT;
        }

        return switch (eventType) {
            case PRESENTATION -> BreathingPreset.PHYSIOLOGICAL_SIGH;
            case EXAM -> BreathingPreset.BOX;
            case INTERVIEW -> BreathingPreset.RESONANCE;
            case DEADLINE, ETC -> BreathingPreset.DEFAULT;
        };
    }
}
