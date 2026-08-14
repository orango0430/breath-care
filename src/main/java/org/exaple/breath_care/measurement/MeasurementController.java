package org.exaple.breath_care.measurement;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.measurement.dto.BaselineResponse;
import org.exaple.breath_care.measurement.dto.MeasurementRequest;
import org.exaple.breath_care.measurement.dto.MeasurementResponse;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/measurements")
@RequiredArgsConstructor
public class MeasurementController {

    private final MeasurementService measurementService;

    /**
     * 측정 결과 전송. 앱은 원시 파형만 보내고 계산은 서버가 한다.
     * 신호 품질이 나쁘면 422 POOR_SIGNAL_QUALITY로 재측정을 요구한다.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<MeasurementResponse>> measure(
            @AuthenticationPrincipal Long userId,
            @Valid @RequestBody MeasurementRequest request) {

        MeasurementResponse created = measurementService.measure(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created));
    }

    /**
     * 개인 기준선 상태. 스트레스 지수가 null인 이유를 앱이 설명할 수 있게 한다.
     * (기준선이 없으면 "기준을 만드는 중이에요 · N회 더")
     */
    @GetMapping("/baseline")
    public ApiResponse<BaselineResponse> baseline(@AuthenticationPrincipal Long userId) {
        return ApiResponse.ok(BaselineResponse.from(measurementService.baselineOf(userId)));
    }

    /** 측정 이력. 최신순. */
    @GetMapping
    public ApiResponse<List<MeasurementResponse>> findInRange(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to) {

        return ApiResponse.ok(measurementService.findInRange(userId, from, to));
    }
}
