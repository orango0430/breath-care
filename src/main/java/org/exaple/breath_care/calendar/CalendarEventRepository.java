package org.exaple.breath_care.calendar;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
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
}
