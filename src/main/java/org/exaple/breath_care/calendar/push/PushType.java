package org.exaple.breath_care.calendar.push;

import java.time.Instant;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

/**
 * 일정 하나에 대해 보내는 알림의 종류. 시점이 곧 성격을 정한다.
 * 발송 시각은 저장하지 않고 일정 시각으로부터 매번 계산한다.
 * 그래야 사용자가 일정을 수정했을 때 예약을 다시 잡지 않아도 자동으로 따라간다.
 */
public enum PushType {

    /** 전날 밤. 수면 전 이완이 목적이라 4-7-8 계열을 권한다. */
    DAY_BEFORE {
        @Override
        public Instant scheduledAt(Instant startAt, ZoneId zone) {
            return startAt.atZone(zone)
                    .toLocalDate()
                    .minusDays(1)
                    .atTime(DAY_BEFORE_HOUR, 0)
                    .atZone(zone)
                    .toInstant();
        }
    },

    /** 일정 직전. 긴급 진정이 목적이라 박스 호흡을 권한다. */
    BEFORE_30M {
        @Override
        public Instant scheduledAt(Instant startAt, ZoneId zone) {
            return startAt.minus(30, ChronoUnit.MINUTES);
        }
    };

    /** "전날 밤"의 기준 시각. 24시간 전이 아니라 고정 시각이어야 새벽 일정에도 밤에 알림이 간다. */
    private static final int DAY_BEFORE_HOUR = 21;

    public abstract Instant scheduledAt(Instant startAt, ZoneId zone);
}
