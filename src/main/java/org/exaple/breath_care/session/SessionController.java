package org.exaple.breath_care.session;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.session.dto.SessionCompleteRequest;
import org.exaple.breath_care.session.dto.SessionResponse;
import org.exaple.breath_care.session.dto.SessionStartRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    /** 세션 시작. 직전에 마친 측정을 함께 넘긴다. */
    @PostMapping
    public ResponseEntity<ApiResponse<SessionResponse>> start(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody SessionStartRequest request) {

        SessionResponse created = sessionService.start(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    /** 세션 종료. 재측정 결과를 묶고 전후 변화를 돌려준다. */
    @PatchMapping("/{sessionId}/complete")
    public ApiResponse<SessionResponse> complete(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long sessionId,
            @Valid @RequestBody SessionCompleteRequest request) {

        return ApiResponse.ok(sessionService.complete(userId, sessionId, request));
    }

    /** 세션 이력. 최신순. 아직 끝나지 않은 세션은 after·change가 비어 있다. */
    @GetMapping
    public ApiResponse<List<SessionResponse>> findInRange(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        return ApiResponse.ok(sessionService.findInRange(userId, from, to));
    }
}
