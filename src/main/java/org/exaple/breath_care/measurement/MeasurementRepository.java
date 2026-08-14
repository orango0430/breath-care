package org.exaple.breath_care.measurement;

import org.springframework.data.domain.Pageable;
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

    /**
     * 기준선 계산용 최근 심박수. 최신순으로 Pageable 만큼만 가져온다.
     * (품질 POOR인 측정은 애초에 저장되지 않으므로 따로 거르지 않는다)
     */
    @Query("""
            select m.hr from Measurement m
            where m.userId = :userId
            order by m.measuredAt desc
            """)
    List<Double> findRecentHr(@Param("userId") Long userId, Pageable pageable);
}
