package org.exaple.breath_care.calendar;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.dto.CalendarEventRequest;
import org.exaple.breath_care.calendar.dto.CalendarEventResponse;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CalendarEventService {

    private final CalendarEventRepository calendarEventRepository;

    @Transactional
    public CalendarEventResponse create(Long userId, CalendarEventRequest request) {
        CalendarEvent event = CalendarEvent.create(
                userId, request.title(), request.eventType(), request.startAt());

        return CalendarEventResponse.from(calendarEventRepository.save(event));
    }

    @Transactional(readOnly = true)
    public List<CalendarEventResponse> findInRange(Long userId, Instant from, Instant to) {
        return calendarEventRepository.findInRange(userId, from, to).stream()
                .map(CalendarEventResponse::from)
                .toList();
    }

    @Transactional
    public CalendarEventResponse update(Long userId, Long eventId, CalendarEventRequest request) {
        CalendarEvent event = findOwned(userId, eventId);
        event.update(request.title(), request.eventType(), request.startAt());
        return CalendarEventResponse.from(event);
    }

    @Transactional
    public void delete(Long userId, Long eventId) {
        calendarEventRepository.delete(findOwned(userId, eventId));
    }

    /**
     * 남의 일정이면 403이 아니라 404를 준다.
     * 403은 "그 id의 일정이 존재한다"는 사실을 알려주는 셈이라 남의 데이터 존재 여부가 새어 나간다.
     */
    private CalendarEvent findOwned(Long userId, Long eventId) {
        return calendarEventRepository.findByIdAndUserId(eventId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND, "일정을 찾을 수 없습니다."));
    }
}
