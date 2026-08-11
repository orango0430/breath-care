package org.exaple.breath_care.calendar.push;

import org.springframework.data.jpa.repository.JpaRepository;

public interface EventPushLogRepository extends JpaRepository<EventPushLog, Long> {

    boolean existsByEventIdAndPushType(Long eventId, PushType pushType);
}
