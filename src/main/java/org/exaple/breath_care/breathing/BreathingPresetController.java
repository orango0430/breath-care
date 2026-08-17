package org.exaple.breath_care.breathing;

import org.exaple.breath_care.breathing.dto.BreathingPresetResponse;
import org.exaple.breath_care.calendar.EventType;
import org.exaple.breath_care.global.response.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

/**
 * 호흡법 목록.
 *
 * <p>앱이 프리셋 이름·설명·타이밍을 하드코딩하지 않게 하려고 연다.
 * 하드코딩해 두면 서버 enum과 어긋난 순간 세션 저장이 통째로 400이 나는데,
 * 그때 원인을 찾기가 아주 번거롭다.
 *
 * <p><b>비회원도 쓴다.</b> 로그인 없이 호흡만 하는 게 기본 사용 흐름이라 인증을 걸지 않는다.
 */
@RestController
@RequestMapping("/api/breathing")
public class BreathingPresetController {

    /**
     * @param eventType 주면 그 일정 종류에 맞는 것만, 없으면 전체.
     *                  배정된 게 없는 종류(마감·기타)는 기본 프리셋 하나가 온다
     */
    @GetMapping("/presets")
    public ApiResponse<List<BreathingPresetResponse>> presets(
            @RequestParam(required = false) EventType eventType) {

        List<BreathingPreset> presets = (eventType == null)
                ? Arrays.asList(BreathingPreset.values())
                : BreathingPreset.forEventType(eventType);

        return ApiResponse.ok(presets.stream().map(BreathingPresetResponse::from).toList());
    }
}
