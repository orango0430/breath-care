package org.exaple.breath_care.calendar;

import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.calendar.dto.CalendarSyncRequest;
import org.exaple.breath_care.calendar.dto.CalendarSyncResponse;
import org.exaple.breath_care.calendar.dto.SyncedEvent;
import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 폰 캘린더 동기화.
 *
 * <p>안드로이드에서 구글 캘린더와 삼성 캘린더는 같은 창구로 읽히므로, 앱이 어느 캘린더에서
 * 가져왔는지 서버가 구분할 필요가 없다. 서버가 지키는 규칙은 두 가지다.
 *
 * <ul>
 *   <li><b>직접 입력한 일정은 절대 건드리지 않는다.</b> 동기화가 손으로 넣은 일정을 지우면
 *       사용자는 앱을 신뢰할 수 없다</li>
 *   <li><b>몇 번을 실행해도 결과가 같다.</b> externalId로 같은 일정을 알아보기 때문에
 *       재동기화로 일정이 불어나지 않는다</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class CalendarSyncService {

    private final CalendarEventRepository eventRepository;

    @Transactional
    public CalendarSyncResponse sync(Long userId, CalendarSyncRequest request) {
        if (!request.from().isBefore(request.to())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "동기화 시작 시각이 종료 시각보다 앞서야 합니다.");
        }

        Map<String, SyncedEvent> incoming = incomingByExternalId(request.events());
        Map<String, CalendarEvent> stored = storedByExternalId(userId, incoming.keySet());

        int created = 0;
        int updated = 0;
        List<CalendarEvent> newEvents = new ArrayList<>();

        for (SyncedEvent event : incoming.values()) {
            CalendarEvent existing = stored.get(event.externalId());

            if (existing == null) {
                newEvents.add(CalendarEvent.fromPhone(userId, event.title(), event.startAt(), event.externalId()));
                created++;
            } else if (changed(existing, event)) {
                existing.syncFrom(event.title(), event.startAt());
                updated++;
            }
        }
        eventRepository.saveAll(newEvents);

        int deleted = removeVanished(userId, request, incoming.keySet());

        return new CalendarSyncResponse(created, updated, deleted);
    }

    /**
     * 폰에서 지워진 일정을 함께 지운다.
     *
     * <p>이걸 하지 않으면 취소된 시험에 대해 알림이 계속 간다. 다만 <b>앱이 실제로 훑은
     * 구간 안에서만</b> 지운다. 구간 밖의 일정은 이번 요청에 없는 게 당연하기 때문이다.
     */
    private int removeVanished(Long userId, CalendarSyncRequest request, Set<String> incomingIds) {
        List<CalendarEvent> vanished = eventRepository
                .findPhoneEventsInRange(userId, request.from(), request.to()).stream()
                .filter(event -> !incomingIds.contains(event.getExternalId()))
                .toList();

        eventRepository.deleteAll(vanished);
        return vanished.size();
    }

    /**
     * 같은 externalId가 두 번 오면 뒤엣것을 쓴다.
     * 폰 캘린더가 반복 일정을 펼쳐 보낼 때 중복이 섞일 수 있는데, 그대로 저장하면
     * 유니크 제약에 걸려 동기화 전체가 실패한다.
     */
    private Map<String, SyncedEvent> incomingByExternalId(List<SyncedEvent> events) {
        Map<String, SyncedEvent> byId = new HashMap<>();
        events.forEach(event -> byId.put(event.externalId(), event));
        return byId;
    }

    private Map<String, CalendarEvent> storedByExternalId(Long userId, Set<String> externalIds) {
        if (externalIds.isEmpty()) {
            return Map.of();
        }

        Map<String, CalendarEvent> byId = new HashMap<>();
        eventRepository.findByUserIdAndSourceAndExternalIdIn(userId, EventSource.PHONE, new LinkedHashSet<>(externalIds))
                .forEach(event -> byId.put(event.getExternalId(), event));

        return byId;
    }

    /** 바뀐 게 없으면 갱신 수에 넣지 않는다. 앱이 "3개 갱신됨"을 매번 띄우면 의미가 없다. */
    private boolean changed(CalendarEvent existing, SyncedEvent event) {
        return !existing.getTitle().equals(event.title())
                || !existing.getStartAt().equals(event.startAt());
    }
}
