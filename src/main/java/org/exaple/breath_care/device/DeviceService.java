package org.exaple.breath_care.device;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.device.dto.DeviceRegisterRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final UserDeviceRepository userDeviceRepository;

    /**
     * 앱이 FCM 토큰을 받을 때마다 호출한다(로그인 직후, 토큰 갱신 시).
     * 이미 있는 토큰이면 소유자를 지금 로그인한 사용자로 옮긴다.
     * 이 한 줄이 "같은 폰에 다른 계정이 로그인했을 때 이전 사용자 알림이 가는" 사고를 막는다.
     */
    @Transactional
    public void register(Long userId, DeviceRegisterRequest request) {
        userDeviceRepository.findByFcmToken(request.fcmToken())
                .ifPresentOrElse(
                        device -> device.reassignTo(userId, request.platform()),
                        () -> userDeviceRepository.save(
                                UserDevice.create(userId, request.fcmToken(), request.platform())));
    }

    /** 로그아웃·기기 해제. 내 토큰만 지울 수 있다. */
    @Transactional
    public void unregister(Long userId, String fcmToken) {
        if (fcmToken == null || fcmToken.isBlank()) {
            return;
        }
        userDeviceRepository.deleteByUserIdAndFcmToken(userId, fcmToken);
    }

    /** 탈퇴 시. 계정이 사라지므로 모든 기기를 정리한다. */
    @Transactional
    public void unregisterAll(Long userId) {
        userDeviceRepository.deleteAllByUserId(userId);
    }

    /**
     * FCM이 "더는 유효하지 않은 토큰"이라고 알려준 경우 제거한다(앱 삭제, 토큰 만료 등).
     * 소유자를 따지지 않는다. 토큰 자체가 죽었으므로 누구 것이든 남겨둘 이유가 없다.
     */
    @Transactional
    public void removeDeadToken(String fcmToken) {
        userDeviceRepository.findByFcmToken(fcmToken)
                .ifPresent(userDeviceRepository::delete);
    }

    /** 발송 대상 토큰. FCM 연동 시 여기서 받은 토큰으로 보낸다. */
    @Transactional(readOnly = true)
    public List<String> tokensOf(Long userId) {
        return userDeviceRepository.findAllByUserId(userId).stream()
                .map(UserDevice::getFcmToken)
                .toList();
    }
}
