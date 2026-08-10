package org.exaple.breath_care.user.dto;

import org.exaple.breath_care.user.User;

public record UserResponse(Long id, String email, String nickname) {

    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getEmail(), user.getNickname());
    }
}
