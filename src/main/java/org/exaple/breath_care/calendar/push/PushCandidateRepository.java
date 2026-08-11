package org.exaple.breath_care.calendar.push;

import org.exaple.breath_care.calendar.CalendarEvent;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

/**
 * 발송 후보 조회 전용. 읽는 대상은 CalendarEvent지만 쓰임새가 알림이라 push 패키지에 둔다.
 * (캘린더 CRUD 쪽 리포지토리가 알림을 몰라도 되게 하려는 목적)
 */
public interface PushCandidateRepository extends Repository<CalendarEvent, Long> {

    /**
     * 아직 해당 알림을 보내지 않은 일정들. 정확한 발송 시각 판정은 조회 후 자바에서 한다.
     * (전날 21시 같은 규칙은 SQL로 표현하기 나쁘고, 이 앱의 데이터량에서는 이 편이 단순하다)
     */
    @Query("""
            select e from CalendarEvent e
            where e.startAt >= :from and e.startAt <= :to
              and not exists (
                    select 1 from EventPushLog l
                    where l.eventId = e.id and l.pushType = :pushType
              )
            order by e.startAt asc
            """)
    List<CalendarEvent> findPushCandidates(@Param("from") Instant from,
                                           @Param("to") Instant to,
                                           @Param("pushType") PushType pushType);
}
