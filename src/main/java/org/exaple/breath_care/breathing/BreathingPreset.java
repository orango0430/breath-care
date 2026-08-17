package org.exaple.breath_care.breathing;

import org.exaple.breath_care.calendar.EventType;

import java.util.Arrays;
import java.util.List;

/**
 * 호흡법 프리셋 8종.
 *
 * <p>이름·설명·상황 배정은 프론트엔드가 이미 구현해 둔 8종을 그대로 옮긴 것이다
 * ({@code recommended_breathing_screen.dart}). 서버가 새로 정한 게 아니라 화면과 맞춘 것이므로,
 * 바꾸려면 양쪽을 같이 바꿔야 한다.
 *
 * <p><b>초 단위 타이밍은 서버가 가진다.</b> 앱에는 아직 프리셋별 타이밍이 없고
 * 고정 10초 애니메이션만 있어서, 여기서 내려주면 앱을 다시 배포하지 않고도 조정할 수 있다.
 *
 * <p>{@code suitedFor}는 일정 종류별 추천에 쓴다. 한 종류에 여러 프리셋이 붙는다.
 */
public enum BreathingPreset {

    /** 긴장을 천천히 가라앉힌다. 날숨이 길어 부교감이 올라간다 */
    FOUR_SEVEN_EIGHT("4-7-8 호흡", "긴장을 천천히 가라앉히는 호흡", EventType.PRESENTATION,
            BreathStep.inhale(4), BreathStep.hold(7), BreathStep.exhale(8)),

    /** 네 구간이 같아 세기 쉽다. 몰입·집중용 */
    BOX("4-4-4-4 박스 호흡", "몰입 및 집중력 극대화 호흡", EventType.EXAM,
            BreathStep.inhale(4), BreathStep.hold(4), BreathStep.exhale(4), BreathStep.hold(4)),

    /** 분당 약 5.5회. HRV가 가장 커지는 것으로 알려진 속도다 */
    RESONANCE("5.5-5.5 공진 호흡", "자율신경 균형 및 HRV 수치 극대화", EventType.INTERVIEW,
            BreathStep.inhale(5.5), BreathStep.exhale(5.5)),

    /**
     * 들숨을 두 번 겹쳐 쉰 뒤 길게 내쉰다. 효과가 가장 빠르다.
     * 들숨이 연달아 나오는 유일한 프리셋이라 {@link BreathStep} 목록 구조가 필요했다.
     */
    PHYSIOLOGICAL_SIGH("생리학적 한숨", "급속 CO₂ 배출 및 즉각적 심박수 강하", EventType.PRESENTATION,
            BreathStep.inhale(1.5), BreathStep.inhale(1), BreathStep.exhale(6)),

    /** 멈춤이 없어 부담이 적다. 초보자·기본값 */
    RELAX_FOUR_SIX("4-6 릴랙스 호흡", "초보자 맞춤형 마일드 이완 및 안정을 도움", EventType.INTERVIEW,
            BreathStep.inhale(4), BreathStep.exhale(6)),

    /** 박스 호흡의 멈춤을 절반으로 줄인 것. 일상용 */
    SEMI_BOX("4-2-4-2 세미 박스 호흡", "저부담 인지 조절 및 일상 루틴 유지", EventType.EXAM,
            BreathStep.inhale(4), BreathStep.hold(2), BreathStep.exhale(4), BreathStep.hold(2)),

    /** 날숨을 길게 가져가 복부를 쓰게 한다 */
    DIAPHRAGMATIC("2-1-4-1 횡격막 복식호흡", "횡격막 가동 및 복부 내장기 긴장 해소", EventType.PRESENTATION,
            BreathStep.inhale(2), BreathStep.hold(1), BreathStep.exhale(4), BreathStep.hold(1)),

    /**
     * 유일하게 <b>들숨이 날숨보다 길다.</b> 이완이 아니라 각성이 목적이라 그렇다.
     * 자기 전에 추천하면 안 된다.
     */
    AWAKENING("4-1-2-1 각성 호흡", "혈류 산소 순환 촉진 및 두뇌 에너징", EventType.EXAM,
            BreathStep.inhale(4), BreathStep.hold(1), BreathStep.exhale(2), BreathStep.hold(1));

    /** 일정 종류를 모를 때(폰 캘린더 동기화 등) 쓰는 기본값. 멈춤이 없어 누구에게나 무난하다. */
    public static final BreathingPreset DEFAULT = RELAX_FOUR_SIX;

    private final String label;
    private final String description;
    private final EventType suitedFor;
    private final List<BreathStep> steps;

    BreathingPreset(String label, String description, EventType suitedFor, BreathStep... steps) {
        this.label = label;
        this.description = description;
        this.suitedFor = suitedFor;
        this.steps = List.of(steps);
    }

    public String getLabel() {
        return label;
    }

    public String getDescription() {
        return description;
    }

    public EventType getSuitedFor() {
        return suitedFor;
    }

    public List<BreathStep> getSteps() {
        return steps;
    }

    /** 한 주기에 걸리는 시간(초). 앱이 "1분에 약 5회" 같은 안내를 만들 때 쓴다. */
    public double cycleSeconds() {
        return steps.stream().mapToDouble(BreathStep::seconds).sum();
    }

    /**
     * 일정 종류에 맞는 프리셋들. 없으면 {@link #DEFAULT} 하나를 준다.
     *
     * <p>마감·기타에는 배정된 프리셋이 없다. 프론트가 발표·시험·면접 세 가지만 나눠 뒀기 때문이다.
     */
    public static List<BreathingPreset> forEventType(EventType eventType) {
        if (eventType == null) {
            return List.of(DEFAULT);
        }

        List<BreathingPreset> matched = Arrays.stream(values())
                .filter(preset -> preset.suitedFor == eventType)
                .toList();

        return matched.isEmpty() ? List.of(DEFAULT) : matched;
    }
}
