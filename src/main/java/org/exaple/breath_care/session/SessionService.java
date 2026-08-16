package org.exaple.breath_care.session;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.CalendarEventRepository;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.exaple.breath_care.measurement.Measurement;
import org.exaple.breath_care.measurement.MeasurementRepository;
import org.exaple.breath_care.session.dto.MetricSnapshot;
import org.exaple.breath_care.session.dto.SessionCompleteRequest;
import org.exaple.breath_care.session.dto.SessionResponse;
import org.exaple.breath_care.session.dto.SessionStartRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final BreathingSessionRepository sessionRepository;
    private final MeasurementRepository measurementRepository;
    private final CalendarEventRepository calendarEventRepository;

    @Transactional
    public SessionResponse start(Long userId, SessionStartRequest request) {
        Measurement before = findOwnedMeasurement(userId, request.preMeasurementId());
        verifyEventOwnedIfPresent(userId, request.calendarEventId());

        BreathingSession session = sessionRepository.save(BreathingSession.start(
                userId, request.preset(), before.getId(), request.calendarEventId()));

        return SessionResponse.of(session, MetricSnapshot.from(before), null);
    }

    @Transactional
    public SessionResponse complete(Long userId, Long sessionId, SessionCompleteRequest request) {
        BreathingSession session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "세션을 찾을 수 없습니다."));

        if (session.isCompleted()) {
            throw new BusinessException(ErrorCode.SESSION_ALREADY_COMPLETED);
        }

        Measurement after = findOwnedMeasurement(userId, request.postMeasurementId());
        session.complete(after.getId());

        Measurement before = findOwnedMeasurement(userId, session.getPreMeasurementId());
        return SessionResponse.of(session, MetricSnapshot.from(before), MetricSnapshot.from(after));
    }

    @Transactional(readOnly = true)
    public List<SessionResponse> findInRange(Long userId, Instant from, Instant to) {
        List<BreathingSession> sessions = sessionRepository.findInRange(userId, from, to);
        Map<Long, Measurement> measurements = loadMeasurementsOf(sessions);

        return sessions.stream()
                .map(session -> SessionResponse.of(
                        session,
                        snapshotOf(measurements, session.getPreMeasurementId()),
                        snapshotOf(measurements, session.getPostMeasurementId())))
                .toList();
    }

    /** 세션마다 측정을 하나씩 조회하면 N+1이 된다. 한 번에 모아 온다. */
    private Map<Long, Measurement> loadMeasurementsOf(List<BreathingSession> sessions) {
        Set<Long> ids = sessions.stream()
                .flatMap(session -> Stream.of(session.getPreMeasurementId(), session.getPostMeasurementId()))
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());

        return measurementRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(Measurement::getId, Function.identity()));
    }

    private MetricSnapshot snapshotOf(Map<Long, Measurement> measurements, Long measurementId) {
        return Optional.ofNullable(measurementId)
                .map(measurements::get)
                .map(MetricSnapshot::from)
                .orElse(null);
    }

    private Measurement findOwnedMeasurement(Long userId, Long measurementId) {
        return measurementRepository.findByIdAndUserId(measurementId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "측정 기록을 찾을 수 없습니다."));
    }

    private void verifyEventOwnedIfPresent(Long userId, Long calendarEventId) {
        if (calendarEventId == null) {
            return;
        }
        calendarEventRepository.findByIdAndUserId(calendarEventId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "일정을 찾을 수 없습니다."));
    }
}
