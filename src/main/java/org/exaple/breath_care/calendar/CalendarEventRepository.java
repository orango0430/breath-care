package org.exaple.breath_care.calendar;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface CalendarEventRepository extends JpaRepository<CalendarEvent, Long> {

    /** 항상 userId를 함께 조건에 넣는다. 남의 일정에 접근하지 못하게 하는 유일한 방어선이다. */
    Optional<CalendarEvent> findByIdAndUserId(Long id, Long userId);

    @Query("""
            select e from CalendarEvent e
            where e.userId = :userId
              and (:from is null or e.startAt >= :from)
              and (:to   is null or e.startAt <  :to)
            order by e.startAt asc
            """)
    List<CalendarEvent> findInRange(@Param("userId") Long userId,
                                    @Param("from") Instant from,
                                    @Param("to") Instant to);

    /**
     * 동기화 대상 중 이미 저장돼 있는 것들.
     *
     * <p>기간이 아니라 externalId로 찾는 이유는, 사용자가 일정을 옮기면 저장된 시각이
     * 이번 동기화 구간 밖일 수 있기 때문이다. 기간으로만 찾으면 같은 일정을 새로 만들려다
     * 유니크 제약에 걸린다.
     */
    List<CalendarEvent> findByUserIdAndSourceAndExternalIdIn(Long userId, EventSource source,
                                                             Collection<String> externalIds);

    /** 폰에서 지워진 일정을 가려내기 위해, 이번에 훑은 구간의 폰 일정을 모두 가져온다. */
    @Query("""
            select e from CalendarEvent e
            where e.userId = :userId
              and e.source = org.exaple.breath_care.calendar.EventSource.PHONE
              and e.startAt >= :from
              and e.startAt <  :to
            """)
    List<CalendarEvent> findPhoneEventsInRange(@Param("userId") Long userId,
                                               @Param("from") Instant from,
                                               @Param("to") Instant to);
}
