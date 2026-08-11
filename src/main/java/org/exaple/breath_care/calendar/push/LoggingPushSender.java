package org.exaple.breath_care.calendar.push;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * FCM 연동 전까지 쓰는 임시 구현. 실제로 보내지 않고 로그만 남긴다.
 * FCM 구현체가 생기면 그쪽에 @Primary를 붙이거나 이 클래스를 제거한다.
 */
@Component
public class LoggingPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingPushSender.class);

    @Override
    public void send(PushMessage message) {
        log.info("[PUSH-DRYRUN] userId={} eventId={} type={} title={} body={}",
                message.userId(), message.eventId(), message.pushType(), message.title(), message.body());
    }
}
