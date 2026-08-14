package org.exaple.breath_care.statistics;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/**
 * 집계 구간을 한국 시간 기준 "날짜" 단위로 정규화한다.
 *
 * <p>측정 시각은 UTC로 저장하지만 "요일별 평균" 같은 건 사용자가 사는 시간대로 끊어야 한다.
 * 예를 들어 밤 11시(14:00Z) 측정은 KST로 같은 날이지만, UTC 기준으로 자르면 다음 날이 된다.
 *
 * @param from 시작일 (포함)
 * @param to   종료일 (포함)
 */
public record DayRange(LocalDate from, LocalDate to) {

    public static final ZoneId ZONE = ZoneId.of("Asia/Seoul");

    /** 기간을 생략했을 때 보여줄 날짜 수. 오늘 포함 최근 일주일. */
    private static final int DEFAULT_DAYS = 7;

    public static DayRange of(Instant from, Instant to) {
        LocalDate end = (to != null) ? to.atZone(ZONE).toLocalDate() : LocalDate.now(ZONE);
        LocalDate start = (from != null) ? from.atZone(ZONE).toLocalDate() : end.minusDays(DEFAULT_DAYS - 1L);

        // 뒤집힌 구간이 들어오면 하루짜리로 좁힌다. 빈 응답보다 낫다.
        return start.isAfter(end) ? new DayRange(end, end) : new DayRange(start, end);
    }

    public Instant startInstant() {
        return from.atStartOfDay(ZONE).toInstant();
    }

    /** 종료일을 포함하기 위해 다음 날 0시를 쓴다. 조회 조건이 미만(&lt;)이기 때문이다. */
    public Instant endInstantExclusive() {
        return to.plusDays(1).atStartOfDay(ZONE).toInstant();
    }

    public LocalDate dateOf(Instant measuredAt) {
        return measuredAt.atZone(ZONE).toLocalDate();
    }

    /** 시작일부터 종료일까지 하루도 빠짐없이. 측정이 없는 날도 차트에 자리가 필요하다. */
    public java.util.List<LocalDate> eachDay() {
        return from.datesUntil(to.plusDays(1)).toList();
    }
}
