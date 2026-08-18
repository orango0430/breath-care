package org.exaple.breath_care.calendar.push;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.CalendarEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * 발송할 때가 된 알림을 찾아 보낸다.
 *
 * <p>발송 예정 시각을 미리 저장해두지 않고 매번 계산한다. 사용자가 일정 시각을 수정해도
 * 예약을 다시 잡을 필요가 없고, 엉뚱한 시각에 알림이 가는 사고를 원천적으로 막을 수 있다.
 */
@Service
@RequiredArgsConstructor
public class CalendarPushService {

    private static final Logger log = LoggerFactory.getLogger(CalendarPushService.class);

    /**
     * P0는 전 사용자를 한국 시간으로 본다.
     * 사용자별 타임존이 필요해지면 User에 zoneId를 두고 여기서 꺼내 쓰면 된다.
     */
    private static final ZoneId ZONE = ZoneId.of("Asia/Seoul");

    /** 예정 시각을 이만큼 넘겼으면 보내지 않는다. 서버가 꺼져 있었다고 새벽에 몰아 보내면 안 된다. */
    private static final Duration LATE_TOLERANCE = Duration.ofMinutes(10);

    /**
     * 이 시간대에는 보내지 않는다.
     *
     * <p>전날 밤 알림이 22시로 옮겨지면서 23시로 미뤘다. 22시로 두면 알림 예정 시각이
     * 조용시간 첫 순간과 겹쳐 <b>한 건도 나가지 않는다.</b> 오류도 안 나고 그냥 조용히 없어진다.
     */
    private static final LocalTime QUIET_FROM = LocalTime.of(23, 0);
    private static final LocalTime QUIET_TO = LocalTime.of(8, 0);

    /** 후보를 넉넉히 훑기 위한 조회 폭. DAY_BEFORE가 최대 하루 앞이라 이틀이면 충분하다. */
    private static final Duration LOOKAHEAD = Duration.ofDays(2);

    private final PushCandidateRepository pushCandidateRepository;
    private final EventPushLogRepository pushLogRepository;
    private final PushMessageFactory messageFactory;
    private final PushSender pushSender;

    @Transactional
    public int dispatchDue(Instant now) {
        int sent = 0;

        for (PushType pushType : PushType.values()) {
            for (CalendarEvent event : candidates(now, pushType)) {
                if (dispatchIfDue(event, pushType, now)) {
                    sent++;
                }
            }
        }
        return sent;
    }

    private List<CalendarEvent> candidates(Instant now, PushType pushType) {
        // 이미 지난 일정은 볼 필요가 없다. BEFORE_30M 때문에 살짝 과거까지만 포함한다.
        Instant from = now.minus(1, ChronoUnit.HOURS);
        Instant to = now.plus(LOOKAHEAD);
        return pushCandidateRepository.findPushCandidates(from, to, pushType);
    }

    private boolean dispatchIfDue(CalendarEvent event, PushType pushType, Instant now) {
        Instant scheduledAt = pushType.scheduledAt(event.getStartAt(), ZONE);

        if (scheduledAt.isAfter(now)) {
            return false;                                   // 아직 때가 아님
        }
        if (scheduledAt.isBefore(now.minus(LATE_TOLERANCE))) {
            return false;                                   // 너무 늦음 — 조용히 넘긴다
        }
        if (isQuietHour(now)) {
            return false;
        }

        try {
            pushSender.send(messageFactory.create(event, pushType));
            pushLogRepository.save(new EventPushLog(event.getId(), pushType, now));
            return true;
        } catch (DataIntegrityViolationException e) {
            // 유니크 제약 위반 = 다른 실행이 먼저 보냈다는 뜻. 정상 상황이라 넘어간다.
            log.debug("이미 발송된 알림 eventId={} type={}", event.getId(), pushType);
            return false;
        }
    }

    private boolean isQuietHour(Instant now) {
        LocalTime localNow = now.atZone(ZONE).toLocalTime();
        return !localNow.isBefore(QUIET_FROM) || localNow.isBefore(QUIET_TO);
    }
}
