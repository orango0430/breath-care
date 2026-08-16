package org.exaple.breath_care.session;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface BreathingSessionRepository extends JpaRepository<BreathingSession, Long> {

    Optional<BreathingSession> findByIdAndUserId(Long id, Long userId);

    @Query("""
            select s from BreathingSession s
            where s.userId = :userId
              and (:from is null or s.startedAt >= :from)
              and (:to   is null or s.startedAt <  :to)
            order by s.startedAt desc
            """)
    List<BreathingSession> findInRange(@Param("userId") Long userId,
                                       @Param("from") Instant from,
                                       @Param("to") Instant to);
}
