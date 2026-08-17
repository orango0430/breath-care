package org.exaple.breath_care.calendar.push;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.SendResponse;
import org.exaple.breath_care.breathing.BreathingPreset;
import org.exaple.breath_care.device.DeviceService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

/** 스프링 컨텍스트 없이 발송 실패 처리만 검증한다. */
@ExtendWith(MockitoExtension.class)
class FcmPushSenderTest {

    @Mock
    FirebaseMessaging firebaseMessaging;
    @Mock
    DeviceService deviceService;
    @InjectMocks
    FcmPushSender sender;

    private final PushMessage message =
            new PushMessage(1L, "내일 시험이 있어요", "자기 전 호흡할까요?", 10L, PushType.DAY_BEFORE,
                    BreathingPreset.FOUR_SEVEN_EIGHT);

    /** 주의: mock 생성과 스터빙은 given(...) 바깥에서 끝내야 한다. */
    private static SendResponse failureWith(MessagingErrorCode code) {
        return failureWith(code, com.google.firebase.ErrorCode.INTERNAL);
    }

    private static SendResponse failureWith(MessagingErrorCode messagingCode,
                                            com.google.firebase.ErrorCode generalCode) {
        FirebaseMessagingException exception = mock(FirebaseMessagingException.class);
        given(exception.getMessagingErrorCode()).willReturn(messagingCode);
        lenient().when(exception.getErrorCode()).thenReturn(generalCode);

        SendResponse response = mock(SendResponse.class);
        given(response.isSuccessful()).willReturn(false);
        given(response.getException()).willReturn(exception);
        return response;
    }

    private static SendResponse success() {
        SendResponse response = mock(SendResponse.class);
        given(response.isSuccessful()).willReturn(true);
        return response;
    }

    private void givenBatch(List<SendResponse> responses, int failureCount) throws Exception {
        BatchResponse batch = mock(BatchResponse.class);
        given(batch.getFailureCount()).willReturn(failureCount);
        given(batch.getResponses()).willReturn(responses);
        given(firebaseMessaging.sendEachForMulticast(any(MulticastMessage.class))).willReturn(batch);
    }

    @Test
    @DisplayName("등록된 기기가 없으면 FCM을 호출하지 않는다")
    void skipsWhenNoDevice() {
        given(deviceService.tokensOf(1L)).willReturn(List.of());

        sender.send(message);

        verifyNoInteractions(firebaseMessaging);
    }

    @Test
    @DisplayName("UNREGISTERED 토큰은 삭제한다 (앱을 지운 사용자)")
    void removesUnregisteredToken() throws Exception {
        given(deviceService.tokensOf(1L)).willReturn(List.of("dead-token"));
        List<SendResponse> responses = List.of(failureWith(MessagingErrorCode.UNREGISTERED));
        givenBatch(responses, 1);

        sender.send(message);

        verify(deviceService).removeDeadToken("dead-token");
    }

    @Test
    @DisplayName("형식이 깨진 토큰도 삭제한다 (messagingErrorCode가 비어 있는 경우)")
    void removesMalformedToken() throws Exception {
        given(deviceService.tokensOf(1L)).willReturn(List.of("broken-token"));
        // 실제 FCM 응답: messagingErrorCode=null, errorCode=INVALID_ARGUMENT
        List<SendResponse> responses =
                List.of(failureWith(null, com.google.firebase.ErrorCode.INVALID_ARGUMENT));
        givenBatch(responses, 1);

        sender.send(message);

        verify(deviceService).removeDeadToken("broken-token");
    }

    @Test
    @DisplayName("일시적 오류에는 토큰을 지우지 않는다")
    void keepsTokenOnTemporaryFailure() throws Exception {
        given(deviceService.tokensOf(1L)).willReturn(List.of("alive-token"));
        List<SendResponse> responses = List.of(failureWith(MessagingErrorCode.UNAVAILABLE));
        givenBatch(responses, 1);

        sender.send(message);

        verify(deviceService, never()).removeDeadToken(any());
    }

    @Test
    @DisplayName("여러 기기 중 죽은 토큰만 골라 지운다")
    void removesOnlyDeadTokenAmongMany() throws Exception {
        given(deviceService.tokensOf(1L)).willReturn(List.of("alive", "dead"));
        List<SendResponse> responses = List.of(success(), failureWith(MessagingErrorCode.UNREGISTERED));
        givenBatch(responses, 1);

        sender.send(message);

        verify(deviceService).removeDeadToken("dead");
        verify(deviceService, never()).removeDeadToken("alive");
    }

    @Test
    @DisplayName("FCM 호출이 통째로 실패해도 예외를 밖으로 던지지 않는다")
    void swallowsFirebaseException() throws Exception {
        given(deviceService.tokensOf(1L)).willReturn(List.of("token"));
        FirebaseMessagingException failure = mock(FirebaseMessagingException.class);
        given(firebaseMessaging.sendEachForMulticast(any(MulticastMessage.class))).willThrow(failure);

        sender.send(message);   // 예외가 새어 나가면 이 테스트가 실패한다

        verify(deviceService, never()).removeDeadToken(any());
    }
}
