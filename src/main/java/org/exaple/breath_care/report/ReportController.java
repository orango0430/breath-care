package org.exaple.breath_care.report;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.report.dto.ReportResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 주간 AI 리포트. 회원 전용이다 — 비회원은 측정 이력이 서버에 없어 집계할 대상이 없다.
 *
 * <p>조회와 생성을 굳이 나눈 이유는 비용이다. 화면을 열 때마다 도는 GET이 유료 호출을
 * 일으키면 안 된다. 그래서 GET은 저장된 것만 주고, 생성은 사용자가 버튼을 눌러 POST할 때만 한다.
 */
@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /**
     * 이번 주 리포트 조회. <b>Gemini를 부르지 않는다.</b>
     * 아직 만든 적이 없으면 NOT_FOUND다. 앱은 그때 "리포트 만들기" 버튼을 보여주면 된다.
     */
    @GetMapping("/weekly")
    public ApiResponse<ReportResponse> weekly(@AuthenticationPrincipal Long userId) {
        return ApiResponse.ok(reportService.find(userId));
    }

    /**
     * 이번 주 리포트 생성. 이미 있으면 저장된 걸 그대로 주고 호출하지 않는다
     * (응답의 {@code cached}가 true).
     *
     * @param refresh 이미 있는 리포트를 다시 만들고 싶을 때만 true.
     *                마지막 생성 후 쿨다운이 지나지 않았으면 무시된다
     */
    @PostMapping("/weekly")
    public ApiResponse<ReportResponse> generateWeekly(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "false") boolean refresh) {

        return ApiResponse.ok(reportService.generate(userId, refresh));
    }
}
