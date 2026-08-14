package org.exaple.breath_care.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    /** BCrypt 해시. 평문은 어디에도 저장하지 않는다. <b>소셜 회원은 비어 있다.</b> */
    @Column(length = 60)
    private String password;

    @Column(length = 50)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private AuthProvider provider;

    /** 소셜 로그인 제공자가 매기는 고유 식별자. LOCAL 회원은 비어 있다. */
    @Column(length = 128)
    private String providerId;

    @Column(nullable = false)
    private Instant createdAt;

    /** 탈퇴 시각. null이 아니면 탈퇴한 회원. */
    private Instant deletedAt;

    private User(String email, String encodedPassword, String nickname,
                 AuthProvider provider, String providerId) {
        this.email = email;
        this.password = encodedPassword;
        this.nickname = nickname;
        this.provider = provider;
        this.providerId = providerId;
        this.createdAt = Instant.now();
    }

    public static User create(String email, String encodedPassword, String nickname) {
        return new User(email, encodedPassword, nickname, AuthProvider.LOCAL, null);
    }

    /** 소셜 회원. 비밀번호가 없으므로 자체 로그인으로는 들어올 수 없다. */
    public static User createSocial(String email, String nickname,
                                    AuthProvider provider, String providerId) {
        return new User(email, null, nickname, provider, providerId);
    }

    /**
     * 자체 가입 계정에 소셜 로그인을 붙인다.
     *
     * <p>사용자는 자기가 어느 쪽으로 가입했는지 기억하지 못한다. 같은 이메일이면
     * 새 계정을 만드는 대신 기존 계정에 연결해, 측정 이력이 둘로 갈리지 않게 한다.
     * 비밀번호는 그대로 두므로 자체 로그인도 계속 쓸 수 있다.
     */
    public void linkSocial(AuthProvider provider, String providerId) {
        this.provider = provider;
        this.providerId = providerId;
    }

    /** 비밀번호로 로그인할 수 있는 계정인지. 소셜 전용 계정은 해시가 없다. */
    public boolean hasPassword() {
        return password != null;
    }

    public boolean isWithdrawn() {
        return deletedAt != null;
    }

    /**
     * 탈퇴 처리. 측정·세션 기록은 통계를 위해 남기되 개인정보는 지운다.
     * 이메일은 유니크 제약이 걸려 있어 같은 주소로 재가입할 수 있도록 치환한다.
     */
    public void withdraw() {
        this.deletedAt = Instant.now();
        this.email = "deleted_" + this.id + "@deleted.local";
        this.password = null;
        this.nickname = null;
        // 이메일과 같은 이유로 비운다. 남겨 두면 유니크 제약에 걸려
        // 같은 구글 계정으로 다시 가입할 수 없다.
        this.providerId = null;
    }
}
