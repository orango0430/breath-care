package org.exaple.breath_care.user.dto;

public record LoginResponse(
        String accessToken,
        String tokenType,
        long expiresInSec,
        UserResponse user
) {
    public static LoginResponse of(String accessToken, long expiresInSec, UserResponse user) {
        return new LoginResponse(accessToken, "Bearer", expiresInSec, user);
    }
}
