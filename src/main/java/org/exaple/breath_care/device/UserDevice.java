package org.exaple.breath_care.device;

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

/**
 * 푸시를 받을 기기. 서버는 userId만 알기 때문에, 실제로 어디로 보낼지는 이 표가 알려준다.
 *
 * <p>fcm_token은 앱 설치 하나를 가리키므로 전역 유니크다. 같은 폰에 다른 계정이 로그인하면
 * 새 소유자로 옮겨가야지, 행이 두 개가 되면 이전 사용자의 알림이 남의 폰에 간다.
 */
@Entity
@Table(name = "user_device")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false, unique = true, length = 512)
    private String fcmToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Platform platform;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    private UserDevice(Long userId, String fcmToken, Platform platform) {
        this.userId = userId;
        this.fcmToken = fcmToken;
        this.platform = platform;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public static UserDevice create(Long userId, String fcmToken, Platform platform) {
        return new UserDevice(userId, fcmToken, platform);
    }

    /** 같은 기기를 다른 계정이 쓰기 시작한 경우를 포함한다. */
    public void reassignTo(Long userId, Platform platform) {
        this.userId = userId;
        this.platform = platform;
        this.updatedAt = Instant.now();
    }
}
