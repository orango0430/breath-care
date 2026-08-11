package org.exaple.breath_care.calendar.push;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.device.DeviceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * FCM 연동 전까지 쓰는 임시 구현. 실제로 보내지 않고 대상 기기와 내용만 로그로 남긴다.
 * 기기 토큰 조회까지는 실제 경로를 그대로 태우므로, FCM 구현체는 전송 호출만 채우면 된다.
 */
@Component
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "false", matchIfMissing = true)
@RequiredArgsConstructor
public class LoggingPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingPushSender.class);

    private final DeviceService deviceService;

    @Override
    public void send(PushMessage message) {
        List<String> tokens = deviceService.tokensOf(message.userId());

        if (tokens.isEmpty()) {
            log.info("[PUSH-DRYRUN] 등록된 기기가 없어 건너뜀 userId={} eventId={}",
                    message.userId(), message.eventId());
            return;
        }

        log.info("[PUSH-DRYRUN] userId={} eventId={} type={} devices={} title={} body={}",
                message.userId(), message.eventId(), message.pushType(), tokens.size(),
                message.title(), message.body());
    }
}
