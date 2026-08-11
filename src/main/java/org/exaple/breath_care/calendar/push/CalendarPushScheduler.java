package org.exaple.breath_care.calendar.push;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * 매분 정각에 발송 대상을 확인한다. 판단 로직은 전부 서비스에 있고 여기는 방아쇠만 당긴다.
 * (테스트에서는 push.scheduler.enabled=false로 꺼두고 서비스를 직접 호출한다)
 */
@Component
@ConditionalOnProperty(name = "push.scheduler.enabled", havingValue = "true", matchIfMissing = true)
@RequiredArgsConstructor
public class CalendarPushScheduler {

    private static final Logger log = LoggerFactory.getLogger(CalendarPushScheduler.class);

    private final CalendarPushService calendarPushService;

    @Scheduled(cron = "0 * * * * *")
    public void dispatch() {
        try {
            int sent = calendarPushService.dispatchDue(Instant.now());
            if (sent > 0) {
                log.info("일정 알림 {}건 발송", sent);
            }
        } catch (Exception e) {
            // 여기서 예외가 새어 나가면 스케줄러가 멈춘다. 반드시 삼킨다.
            log.error("일정 알림 발송 중 오류", e);
        }
    }
}
