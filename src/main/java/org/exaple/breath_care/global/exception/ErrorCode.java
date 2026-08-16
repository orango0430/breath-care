package org.exaple.breath_care.global.exception;

import org.springframework.http.HttpStatus;

/**
 * API 전역에서 쓰는 에러 코드.
 * 앱(프론트)은 HTTP 상태가 아니라 이 code 값으로 분기한다.
 */
public enum ErrorCode {

    INVALID_INPUT(HttpStatus.BAD_REQUEST, "입력값이 올바르지 않습니다."),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "인증이 필요합니다."),
    /** 이메일이 없든 비밀번호가 틀리든 같은 코드를 쓴다. 어느 쪽인지 알려주면 가입 여부가 새어 나간다. */
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다."),
    /** 소셜 로그인 토큰이 만료됐거나 유효하지 않다. 앱은 다시 로그인시키면 된다. */
    INVALID_SOCIAL_TOKEN(HttpStatus.UNAUTHORIZED, "로그인 정보가 만료됐어요. 다시 시도해 주세요."),
    FORBIDDEN(HttpStatus.FORBIDDEN, "권한이 없습니다."),
    NOT_FOUND(HttpStatus.NOT_FOUND, "대상을 찾을 수 없습니다."),
    DUPLICATE_EMAIL(HttpStatus.CONFLICT, "이미 가입된 이메일입니다."),
    SESSION_ALREADY_COMPLETED(HttpStatus.CONFLICT, "이미 종료된 세션입니다."),
    METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED, "지원하지 않는 요청 방식입니다."),
    UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Content-Type을 application/json으로 보내주세요."),

    /** 품질 게이트: 손 흔들림·조명 문제 등으로 신호를 신뢰할 수 없을 때. 계산하지 않고 재측정을 요구한다. */
    POOR_SIGNAL_QUALITY(HttpStatus.UNPROCESSABLE_CONTENT, "신호 품질이 낮습니다. 다시 측정해 주세요."),

    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다."),

    /** 서버에 소셜 로그인 설정이 없을 때. 사용자 잘못이 아니므로 5xx로 구분한다. */
    SOCIAL_LOGIN_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "지금은 소셜 로그인을 쓸 수 없어요. 이메일로 로그인해 주세요.");

    private final HttpStatus status;
    private final String defaultMessage;

    ErrorCode(HttpStatus status, String defaultMessage) {
        this.status = status;
        this.defaultMessage = defaultMessage;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getDefaultMessage() {
        return defaultMessage;
    }
}
