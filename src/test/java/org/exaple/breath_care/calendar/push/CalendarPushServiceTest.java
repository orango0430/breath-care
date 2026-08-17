package org.exaple.breath_care.calendar.push;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.exaple.breath_care.calendar.CalendarEvent;
import org.exaple.breath_care.calendar.CalendarEventRepository;
import org.exaple.breath_care.calendar.EventType;
import org.exaple.breath_care.user.User;
import org.exaple.breath_care.user.UserRepository;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@SpringBootTest
@Transactional
class CalendarPushServiceTest {

    @Autowired
    CalendarPushService calendarPushService;
    @Autowired
    CalendarEventRepository calendarEventRepository;
    @Autowired
    UserRepository userRepository;

    @MockitoBean
    PushSender pushSender;

    private Long userId;

    @BeforeEach
    void createUser() {
        userId = userRepository.save(User.create("push@test.com", "{noop}pw", "tester")).getId();
    }

    /** 2026-09-15 14:00 KST 시험. 전날 알림 = 09-14 22:00 KST, 직전 알림 = 09-15 13:30 KST */
    private CalendarEvent exam() {
        return calendarEventRepository.save(
                CalendarEvent.create(userId, "중간고사", EventType.EXAM, null, Instant.parse("2026-09-15T05:00:00Z")));
    }

    private static final Instant DAY_BEFORE_TIME = Instant.parse("2026-09-14T13:00:00Z"); // 09-14 22:00 KST
    private static final Instant BEFORE_30M_TIME = Instant.parse("2026-09-15T04:30:00Z"); // 09-15 13:30 KST

    @Test
    @DisplayName("전날 22시가 되면 DAY_BEFORE 알림을 보낸다")
    void sendsDayBefore() {
        exam();

        int sent = calendarPushService.dispatchDue(DAY_BEFORE_TIME);

        assertThat(sent).isEqualTo(1);
        ArgumentCaptor<PushMessage> captor = ArgumentCaptor.forClass(PushMessage.class);
        verify(pushSender, times(1)).send(captor.capture());
        assertThat(captor.getValue().pushType()).isEqualTo(PushType.DAY_BEFORE);
        assertThat(captor.getValue().title()).contains("내일", "시험");
        assertThat(captor.getValue().userId()).isEqualTo(userId);
    }

    @Test
    @DisplayName("일정 30분 전이 되면 BEFORE_30M 알림을 보낸다")
    void sendsBefore30m() {
        exam();

        int sent = calendarPushService.dispatchDue(BEFORE_30M_TIME);

        assertThat(sent).isEqualTo(1);
        ArgumentCaptor<PushMessage> captor = ArgumentCaptor.forClass(PushMessage.class);
        verify(pushSender).send(captor.capture());
        assertThat(captor.getValue().pushType()).isEqualTo(PushType.BEFORE_30M);
        assertThat(captor.getValue().title()).contains("곧");
    }

    @Test
    @DisplayName("한 일정에 두 알림이 각자의 시각에 한 번씩 간다")
    void sendsBothPushesOnce() {
        exam();

        assertThat(calendarPushService.dispatchDue(DAY_BEFORE_TIME)).isEqualTo(1);
        assertThat(calendarPushService.dispatchDue(BEFORE_30M_TIME)).isEqualTo(1);

        verify(pushSender, times(2)).send(any());
    }

    @Test
    @DisplayName("같은 시각에 여러 번 돌아도 중복 발송하지 않는다")
    void doesNotSendTwice() {
        exam();

        assertThat(calendarPushService.dispatchDue(DAY_BEFORE_TIME)).isEqualTo(1);
        assertThat(calendarPushService.dispatchDue(DAY_BEFORE_TIME)).isZero();
        assertThat(calendarPushService.dispatchDue(DAY_BEFORE_TIME.plusSeconds(120))).isZero();

        verify(pushSender, times(1)).send(any());
    }

    @Test
    @DisplayName("아직 시각이 되지 않았으면 보내지 않는다")
    void doesNotSendBeforeScheduledTime() {
        exam();

        int sent = calendarPushService.dispatchDue(DAY_BEFORE_TIME.minusSeconds(60));

        assertThat(sent).isZero();
        verify(pushSender, never()).send(any());
    }

    @Test
    @DisplayName("예정 시각을 10분 넘게 지나면 보내지 않는다 (서버가 꺼져 있던 경우)")
    void doesNotSendWhenTooLate() {
        exam();

        int sent = calendarPushService.dispatchDue(DAY_BEFORE_TIME.plusSeconds(11 * 60));

        assertThat(sent).isZero();
        verify(pushSender, never()).send(any());
    }

    @Test
    @DisplayName("새벽에는 보내지 않는다")
    void doesNotSendDuringQuietHours() {
        // 09-15 02:00 KST 일정 → 직전 알림은 01:30 KST
        calendarEventRepository.save(
                CalendarEvent.create(userId, "새벽 일정", EventType.ETC, null, Instant.parse("2026-09-14T17:00:00Z")));

        int sent = calendarPushService.dispatchDue(Instant.parse("2026-09-14T16:30:00Z"));

        assertThat(sent).isZero();
        verify(pushSender, never()).send(any());
    }

    @Test
    @DisplayName("일정 종류가 없으면 '일정'으로 문구를 만든다")
    void handlesNullEventType() {
        calendarEventRepository.save(
                CalendarEvent.create(userId, "제목만 있는 일정", null, null, Instant.parse("2026-09-15T05:00:00Z")));

        calendarPushService.dispatchDue(DAY_BEFORE_TIME);

        ArgumentCaptor<PushMessage> captor = ArgumentCaptor.forClass(PushMessage.class);
        verify(pushSender).send(captor.capture());
        assertThat(captor.getValue().title()).isEqualTo("내일 일정이 있어요");
    }
}
