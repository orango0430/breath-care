package org.exaple.breath_care.report;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;

public interface AiReportRepository extends JpaRepository<AiReport, Long> {

    /** 캐시 조회. 남의 리포트를 집어오지 않도록 항상 userId를 함께 조건에 넣는다. */
    Optional<AiReport> findByUserIdAndPeriodStart(Long userId, LocalDate periodStart);
}
