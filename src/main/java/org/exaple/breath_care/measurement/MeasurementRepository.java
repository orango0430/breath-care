package org.exaple.breath_care.measurement;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface MeasurementRepository extends JpaRepository<Measurement, Long> {

    @Query("""
            select m from Measurement m
            where m.userId = :userId
              and (:from is null or m.measuredAt >= :from)
              and (:to   is null or m.measuredAt <  :to)
            order by m.measuredAt desc
            """)
    List<Measurement> findInRange(@Param("userId") Long userId,
                                  @Param("from") Instant from,
                                  @Param("to") Instant to);
}
