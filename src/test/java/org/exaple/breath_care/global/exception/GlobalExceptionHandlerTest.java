package org.exaple.breath_care.global.exception;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 잘못된 요청이 500으로 새어 나가지 않는지 확인한다.
 * 500은 "서버 잘못"이라는 뜻이라, 클라이언트 실수까지 500으로 주면 장애 알림이 무의미해진다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class GlobalExceptionHandlerTest {

    @Autowired
    MockMvc mockMvc;

    @Test
    @DisplayName("Content-Type이 json이 아니면 415")
    void wrongContentType() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .content("email=a@test.com&password=password123"))
                .andExpect(status().isUnsupportedMediaType())
                .andExpect(jsonPath("$.error.code").value("UNSUPPORTED_MEDIA_TYPE"));
    }

    @Test
    @DisplayName("허용되지 않은 HTTP 메서드면 405")
    void wrongHttpMethod() throws Exception {
        mockMvc.perform(get("/api/auth/login"))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.error.code").value("METHOD_NOT_ALLOWED"));
    }

    @Test
    @DisplayName("없는 경로는 404 (인증된 사용자 기준)")
    void unknownPath() throws Exception {
        String token = signupAndLogin();

        mockMvc.perform(get("/api/nope/nothing").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("NOT_FOUND"));
    }

    private String signupAndLogin() throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"err@test.com","password":"password123","nickname":"t"}
                                """))
                .andExpect(status().isCreated());

        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"err@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        return body.substring(start, body.indexOf('"', start));
    }
}
