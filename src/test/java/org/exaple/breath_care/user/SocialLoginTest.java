package org.exaple.breath_care.user;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.user.social.SocialAccount;
import org.exaple.breath_care.user.social.SocialTokenVerifier;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 구글 로그인. 토큰 검증은 Firebase가 하므로 여기서는 검증기를 대역으로 두고
 * <b>계정을 찾고·만들고·연결하는 규칙</b>만 확인한다.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class SocialLoginTest {

    private static final String SOCIAL = "/api/auth/social";
    private static final String BODY = """
            {"idToken":"dummy-token"}
            """;

    @Autowired
    MockMvc mockMvc;
    @Autowired
    UserRepository userRepository;

    @MockitoBean
    SocialTokenVerifier socialTokenVerifier;

    private void googleAccountIs(String providerId, String email, String nickname) {
        given(socialTokenVerifier.verify(any()))
                .willReturn(new SocialAccount(AuthProvider.GOOGLE, providerId, email, nickname));
    }

    private void signupLocally(String email, String password) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"%s","nickname":"local"}
                                """.formatted(email, password)))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("처음 구글로 들어오면 계정이 만들어지고 토큰이 발급된다")
    void createsAccountOnFirstLogin() throws Exception {
        googleAccountIs("google-uid-1", "new@gmail.com", "새 사용자");

        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.user.email").value("new@gmail.com"))
                .andExpect(jsonPath("$.data.user.nickname").value("새 사용자"));

        User created = userRepository.findByEmailAndDeletedAtIsNull("new@gmail.com").orElseThrow();
        assertThat(created.getProvider()).isEqualTo(AuthProvider.GOOGLE);
        assertThat(created.getProviderId()).isEqualTo("google-uid-1");
        // 구글 회원은 비밀번호가 없다
        assertThat(created.hasPassword()).isFalse();
    }

    @Test
    @DisplayName("같은 구글 계정으로 다시 들어와도 계정이 새로 생기지 않는다")
    void reusesAccountOnSecondLogin() throws Exception {
        googleAccountIs("google-uid-1", "repeat@gmail.com", "재방문");

        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk());
        long afterFirst = userRepository.count();

        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk());

        assertThat(userRepository.count()).isEqualTo(afterFirst);
    }

    @Test
    @DisplayName("구글에서 이메일을 바꿔도 같은 계정으로 들어온다")
    void followsProviderIdNotEmail() throws Exception {
        googleAccountIs("google-uid-1", "before@gmail.com", "사용자");
        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk());

        Long idBefore = userRepository.findByEmailAndDeletedAtIsNull("before@gmail.com")
                .orElseThrow().getId();
        long countBefore = userRepository.count();

        // 같은 사람인데 이메일만 바뀐 경우
        googleAccountIs("google-uid-1", "after@gmail.com", "사용자");
        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.user.id").value(idBefore));

        assertThat(userRepository.count()).isEqualTo(countBefore);
    }

    @Test
    @DisplayName("자체 가입한 이메일과 같으면 새 계정을 만들지 않고 연결한다")
    void linksToExistingLocalAccount() throws Exception {
        signupLocally("same@gmail.com", "password123");
        Long localId = userRepository.findByEmailAndDeletedAtIsNull("same@gmail.com")
                .orElseThrow().getId();
        long countBefore = userRepository.count();

        googleAccountIs("google-uid-9", "same@gmail.com", "구글쪽 이름");

        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk())
                // 같은 계정이어야 측정 이력이 갈라지지 않는다
                .andExpect(jsonPath("$.data.user.id").value(localId));

        assertThat(userRepository.count()).isEqualTo(countBefore);

        User linked = userRepository.findById(localId).orElseThrow();
        assertThat(linked.getProvider()).isEqualTo(AuthProvider.GOOGLE);
        assertThat(linked.getProviderId()).isEqualTo("google-uid-9");
    }

    @Test
    @DisplayName("연결된 뒤에도 원래 비밀번호로 로그인할 수 있다")
    void keepsPasswordAfterLinking() throws Exception {
        signupLocally("both@gmail.com", "password123");
        googleAccountIs("google-uid-8", "both@gmail.com", "이름");
        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"both@gmail.com","password":"password123"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    @DisplayName("구글로만 가입한 계정은 비밀번호 로그인이 막힌다")
    void googleOnlyAccountCannotUsePasswordLogin() throws Exception {
        googleAccountIs("google-uid-7", "onlygoogle@gmail.com", "구글전용");
        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"onlygoogle@gmail.com","password":"anything123"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    @DisplayName("토큰이 유효하지 않으면 401")
    void rejectsInvalidToken() throws Exception {
        given(socialTokenVerifier.verify(any()))
                .willThrow(new BusinessException(ErrorCode.INVALID_SOCIAL_TOKEN));

        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON).content(BODY))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("INVALID_SOCIAL_TOKEN"));
    }

    @Test
    @DisplayName("idToken이 비어 있으면 400")
    void rejectsBlankToken() throws Exception {
        mockMvc.perform(post(SOCIAL).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":"  "}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }
}
