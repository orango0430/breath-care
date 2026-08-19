package org.exaple.breath_care.measurement;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.global.response.ApiResponse;
import org.exaple.breath_care.measurement.dto.GuestMeasurementRequest;
import org.exaple.breath_care.measurement.dto.GuestMeasurementResponse;
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
     * 비회원 측정. <b>이 컨트롤러에서 유일하게 인증이 필요 없는 창구다.</b>
     *
     * <p>계산만 하고 저장하지 않는다. 저장을 하지 않으니 201이 아니라 200으로 응답한다.
     */
    @PostMapping("/analyze")
    public ApiResponse<GuestMeasurementResponse> analyze(
            @Valid @RequestBody GuestMeasurementRequest request) {

        return ApiResponse.ok(measurementService.analyze(request));
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
