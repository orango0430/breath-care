package org.exaple.breath_care.user;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerTest {

    @Autowired
    MockMvc mockMvc;

    private static final String SIGNUP = "/api/auth/signup";
    private static final String LOGIN = "/api/auth/login";
    private static final String LOGOUT = "/api/auth/logout";
    private static final String WITHDRAW = "/api/auth/withdraw";

    private String signupBody(String email) {
        return """
                {"email":"%s","password":"password123","nickname":"시원"}
                """.formatted(email);
    }

    private String loginBody(String email, String password) {
        return """
                {"email":"%s","password":"%s"}
                """.formatted(email, password);
    }

    private void signup(String email) throws Exception {
        mockMvc.perform(post(SIGNUP).contentType(MediaType.APPLICATION_JSON).content(signupBody(email)))
                .andExpect(status().isCreated());
    }

    private String loginAndGetToken(String email) throws Exception {
        String body = mockMvc.perform(post(LOGIN).contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(email, "password123")))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        // {"success":true,"data":{"accessToken":"...", ...}}
        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        int end = body.indexOf('"', start);
        return body.substring(start, end);
    }

    @Test
    @DisplayName("회원가입 성공 시 비밀번호는 응답에 포함되지 않는다")
    void signup_success() throws Exception {
        mockMvc.perform(post(SIGNUP).contentType(MediaType.APPLICATION_JSON)
                        .content(signupBody("a@test.com")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.email").value("a@test.com"))
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    @DisplayName("중복 이메일로 가입하면 409")
    void signup_duplicateEmail() throws Exception {
        signup("dup@test.com");

        mockMvc.perform(post(SIGNUP).contentType(MediaType.APPLICATION_JSON)
                        .content(signupBody("dup@test.com")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error.code").value("DUPLICATE_EMAIL"));
    }

    @Test
    @DisplayName("비밀번호가 8자 미만이면 400")
    void signup_shortPassword() throws Exception {
        mockMvc.perform(post(SIGNUP).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"short@test.com","password":"1234"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("로그인 성공 시 액세스 토큰을 발급한다")
    void login_success() throws Exception {
        signup("login@test.com");

        mockMvc.perform(post(LOGIN).contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("login@test.com", "password123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"));
    }

    @Test
    @DisplayName("비밀번호가 틀리거나 없는 계정이면 같은 코드로 응답한다 (가입 여부 노출 방지)")
    void login_invalidCredentials() throws Exception {
        signup("pw@test.com");

        mockMvc.perform(post(LOGIN).contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("pw@test.com", "wrongpassword")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("INVALID_CREDENTIALS"));

        mockMvc.perform(post(LOGIN).contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("nobody@test.com", "password123")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    @DisplayName("토큰 없이 보호된 API를 부르면 401")
    void protectedApi_withoutToken() throws Exception {
        mockMvc.perform(post(LOGOUT))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"));
    }

    @Test
    @DisplayName("로그아웃한 토큰은 더 이상 쓸 수 없다")
    void logout_revokesToken() throws Exception {
        signup("logout@test.com");
        String token = loginAndGetToken("logout@test.com");

        mockMvc.perform(post(LOGOUT).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        // 같은 토큰 재사용 → 무효 목록에 걸려 401
        mockMvc.perform(post(LOGOUT).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("탈퇴하면 로그인할 수 없고 같은 이메일로 재가입할 수 있다")
    void withdraw_thenCannotLogin_andEmailIsFreed() throws Exception {
        signup("bye@test.com");
        String token = loginAndGetToken("bye@test.com");

        mockMvc.perform(delete(WITHDRAW).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(post(LOGIN).contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("bye@test.com", "password123")))
                .andExpect(status().isUnauthorized());

        // 이메일이 치환됐으므로 같은 주소로 재가입 가능
        mockMvc.perform(post(SIGNUP).contentType(MediaType.APPLICATION_JSON)
                        .content(signupBody("bye@test.com")))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("탈퇴 시 사용하던 토큰도 무효화된다")
    void withdraw_revokesToken() throws Exception {
        signup("bye2@test.com");
        String token = loginAndGetToken("bye2@test.com");

        mockMvc.perform(delete(WITHDRAW).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(post(LOGOUT).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("위조된 토큰은 거부한다")
    void forgedToken_rejected() throws Exception {
        mockMvc.perform(post(LOGOUT).header(HttpHeaders.AUTHORIZATION, "Bearer not.a.jwt"))
                .andExpect(status().isUnauthorized());
    }
}
