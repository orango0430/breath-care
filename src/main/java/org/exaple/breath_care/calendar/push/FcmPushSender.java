package org.exaple.breath_care.calendar.push;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.SendResponse;
import lombok.RequiredArgsConstructor;
import org.exaple.breath_care.device.DeviceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
@RequiredArgsConstructor
public class FcmPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);

    private final FirebaseMessaging firebaseMessaging;
    private final DeviceService deviceService;

    @Override
    public void send(PushMessage message) {
        List<String> tokens = deviceService.tokensOf(message.userId());
        if (tokens.isEmpty()) {
            log.info("등록된 기기가 없어 알림을 건너뜀 userId={} eventId={}", message.userId(), message.eventId());
            return;
        }

        MulticastMessage multicast = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(Notification.builder()
                        .setTitle(message.title())
                        .setBody(message.body())
                        .build())
                // 알림을 탭했을 때 앱이 바로 해당 세션을 열 수 있도록 넘긴다.
                .putData("eventId", String.valueOf(message.eventId()))
                .putData("pushType", message.pushType().name())
                .build();

        try {
            BatchResponse response = firebaseMessaging.sendEachForMulticast(multicast);
            handleFailures(tokens, response);
        } catch (FirebaseMessagingException e) {
            // 여기서 던지면 같은 배치의 다른 사용자 알림까지 막힌다. 로그만 남기고 넘어간다.
            log.error("FCM 발송 실패 userId={} eventId={}", message.userId(), message.eventId(), e);
        }
    }

    /** 죽은 토큰은 지운다. 그대로 두면 매번 실패하면서 발송 대상에 계속 남는다. */
    private void handleFailures(List<String> tokens, BatchResponse response) {
        if (response.getFailureCount() == 0) {
            return;
        }

        List<SendResponse> results = response.getResponses();
        for (int i = 0; i < results.size(); i++) {
            SendResponse result = results.get(i);
            if (result.isSuccessful()) {
                continue;
            }

            String token = tokens.get(i);
            FirebaseMessagingException exception = result.getException();

            if (isPermanentlyInvalid(exception)) {
                deviceService.removeDeadToken(token);
                log.info("무효한 기기 토큰 제거 {}", describe(exception));
            } else {
                // 일시적 오류(QUOTA_EXCEEDED, UNAVAILABLE 등)는 토큰을 지우지 않는다.
                log.warn("알림 발송 실패 {}", describe(exception));
            }
        }
    }

    /**
     * 다시 시도해도 소용없는 토큰인지 판단한다.
     *
     * <p>firebase-admin은 에러 코드를 두 층으로 준다. 앱을 지운 사용자는 messagingErrorCode가
     * UNREGISTERED로 오지만, 형식이 깨진 토큰은 messagingErrorCode 없이 일반 INVALID_ARGUMENT로만 온다.
     * 둘 다 보지 않으면 죽은 토큰이 영영 남아 매번 발송 실패를 반복한다.
     */
    private boolean isPermanentlyInvalid(FirebaseMessagingException exception) {
        if (exception == null) {
            return false;
        }

        MessagingErrorCode messagingCode = exception.getMessagingErrorCode();
        if (messagingCode == MessagingErrorCode.UNREGISTERED
                || messagingCode == MessagingErrorCode.SENDER_ID_MISMATCH) {
            return true;
        }

        return exception.getErrorCode() == com.google.firebase.ErrorCode.INVALID_ARGUMENT;
    }

    private String describe(FirebaseMessagingException exception) {
        if (exception == null) {
            return "code=unknown";
        }
        return "code=%s messagingCode=%s".formatted(
                exception.getErrorCode(), exception.getMessagingErrorCode());
    }
}
