package org.exaple.breath_care.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

    /** BCrypt 해시. 평문은 어디에도 저장하지 않는다. */
    @Column(nullable = false, length = 60)
    private String password;

    @Column(length = 50)
    private String nickname;

    @Column(nullable = false)
    private Instant createdAt;

    /** 탈퇴 시각. null이 아니면 탈퇴한 회원. */
    private Instant deletedAt;

    private User(String email, String encodedPassword, String nickname) {
        this.email = email;
        this.password = encodedPassword;
        this.nickname = nickname;
        this.createdAt = Instant.now();
    }

    public static User create(String email, String encodedPassword, String nickname) {
        return new User(email, encodedPassword, nickname);
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
        this.password = "(withdrawn)";
        this.nickname = null;
    }
}
