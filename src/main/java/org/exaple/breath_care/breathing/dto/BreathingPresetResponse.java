package org.exaple.breath_care.breathing.dto;

import org.exaple.breath_care.breathing.BreathStep;
import org.exaple.breath_care.breathing.BreathingPreset;
import org.exaple.breath_care.calendar.EventType;

import java.util.List;

/**
 * @param name         enum 이름. 세션을 저장할 때 앱이 이 값을 그대로 돌려보내면 된다.
 *                     화면에 쓰는 건 label이다
 * @param steps        한 주기의 순서. 들숨이 두 번 연달아 나오는 프리셋이 있으므로
 *                     "들숨·멈춤·날숨" 세 칸으로 가정하지 말고 순서대로 재생해야 한다
 * @param cycleSeconds 한 주기 길이(초)
 * @param suitedFor    이 프리셋이 배정된 일정 종류
 */
public record BreathingPresetResponse(
        String name,
        String label,
        String description,
        List<BreathStep> steps,
        double cycleSeconds,
        EventType suitedFor
) {
    public static BreathingPresetResponse from(BreathingPreset preset) {
        return new BreathingPresetResponse(
                preset.name(),
                preset.getLabel(),
                preset.getDescription(),
                preset.getSteps(),
                preset.cycleSeconds(),
                preset.getSuitedFor());
    }
}
