package org.exaple.breath_care.device;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class DeviceControllerTest {

    private static final String DEVICES = "/api/devices";
    private static final String TOKEN_A = "fcm-token-device-a";

    @Autowired
    MockMvc mockMvc;
    @Autowired
    UserDeviceRepository userDeviceRepository;
    @Autowired
    DeviceService deviceService;

    private String login(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"password123","nickname":"t"}
                                """.formatted(email)))
                .andExpect(status().isCreated());

        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"password123"}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        return body.substring(start, body.indexOf('"', start));
    }

    private void register(String token, String fcmToken) throws Exception {
        mockMvc.perform(post(DEVICES)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fcmToken":"%s","platform":"ANDROID"}
                                """.formatted(fcmToken)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("기기를 등록하면 발송 대상 토큰으로 조회된다")
    void register_thenTokenIsResolvable() throws Exception {
        String token = login("dev1@test.com");

        register(token, TOKEN_A);

        Long userId = userDeviceRepository.findByFcmToken(TOKEN_A).orElseThrow().getUserId();
        assertThat(deviceService.tokensOf(userId)).containsExactly(TOKEN_A);
    }

    @Test
    @DisplayName("같은 토큰을 여러 번 등록해도 행이 늘지 않는다")
    void register_isIdempotent() throws Exception {
        String token = login("dev2@test.com");

        register(token, TOKEN_A);
        register(token, TOKEN_A);
        register(token, TOKEN_A);

        assertThat(userDeviceRepository.findAll()).hasSize(1);
    }

    @Test
    @DisplayName("같은 폰에 다른 계정이 로그인하면 기기 소유자가 넘어간다")
    void register_reassignsDeviceToNewUser() throws Exception {
        String first = login("first@test.com");
        register(first, TOKEN_A);
        Long firstUserId = userDeviceRepository.findByFcmToken(TOKEN_A).orElseThrow().getUserId();

        String second = login("second@test.com");
        register(second, TOKEN_A);
        Long secondUserId = userDeviceRepository.findByFcmToken(TOKEN_A).orElseThrow().getUserId();

        assertThat(secondUserId).isNotEqualTo(firstUserId);
        // 이전 사용자에게는 더 이상 이 기기로 알림이 가지 않는다
        assertThat(deviceService.tokensOf(firstUserId)).isEmpty();
        assertThat(deviceService.tokensOf(secondUserId)).containsExactly(TOKEN_A);
        assertThat(userDeviceRepository.findAll()).hasSize(1);
    }

    @Test
    @DisplayName("기기를 해제하면 발송 대상에서 빠진다")
    void unregister() throws Exception {
        String token = login("dev3@test.com");
        register(token, TOKEN_A);

        mockMvc.perform(delete(DEVICES)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fcmToken":"%s"}
                                """.formatted(TOKEN_A)))
                .andExpect(status().isOk());

        assertThat(userDeviceRepository.findByFcmToken(TOKEN_A)).isEmpty();
    }

    @Test
    @DisplayName("로그아웃 시 fcmToken을 보내면 기기 등록이 해제된다")
    void logout_withToken_removesDevice() throws Exception {
        String token = login("dev4@test.com");
        register(token, TOKEN_A);

        mockMvc.perform(post("/api/auth/logout")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fcmToken":"%s"}
                                """.formatted(TOKEN_A)))
                .andExpect(status().isOk());

        assertThat(userDeviceRepository.findByFcmToken(TOKEN_A)).isEmpty();
    }

    @Test
    @DisplayName("로그아웃 본문이 없어도 기존처럼 동작한다")
    void logout_withoutBody_stillWorks() throws Exception {
        String token = login("dev5@test.com");
        register(token, TOKEN_A);

        mockMvc.perform(post("/api/auth/logout")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        // 토큰을 안 보냈으니 기기는 남는다 (앱이 보내야 한다)
        assertThat(userDeviceRepository.findByFcmToken(TOKEN_A)).isPresent();
    }

    @Test
    @DisplayName("탈퇴하면 등록된 기기가 모두 정리된다")
    void withdraw_removesAllDevices() throws Exception {
        String token = login("dev6@test.com");
        register(token, TOKEN_A);
        register(token, "fcm-token-device-b");

        mockMvc.perform(delete("/api/auth/withdraw")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        assertThat(userDeviceRepository.findAll()).isEmpty();
    }

    @Test
    @DisplayName("토큰 없이 기기를 등록하면 401")
    void register_withoutAuth() throws Exception {
        mockMvc.perform(post(DEVICES)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fcmToken":"x","platform":"ANDROID"}
                                """))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("없는 플랫폼 값이면 400")
    void register_unknownPlatform() throws Exception {
        String token = login("dev7@test.com");

        mockMvc.perform(post(DEVICES)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fcmToken":"x","platform":"WINDOWS"}
                                """))
                .andExpect(status().isBadRequest());
    }
}
