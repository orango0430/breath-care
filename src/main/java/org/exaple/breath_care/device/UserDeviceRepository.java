package org.exaple.breath_care.device;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    Optional<UserDevice> findByFcmToken(String fcmToken);

    List<UserDevice> findAllByUserId(Long userId);

    void deleteByUserIdAndFcmToken(Long userId, String fcmToken);

    void deleteAllByUserId(Long userId);
}
