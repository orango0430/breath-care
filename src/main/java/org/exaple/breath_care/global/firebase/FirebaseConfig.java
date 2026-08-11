package org.exaple.breath_care.global.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;

/**
 * firebase.enabled=true 일 때만 뜬다.
 * 서비스 계정 키가 없는 팀원도 앱을 그대로 실행할 수 있어야 하므로 기본값은 꺼짐이다.
 */
@Configuration
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Bean
    public FirebaseApp firebaseApp(@Value("${firebase.credentials-location}") Resource credentials) throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            // devtools 재시작 시 이미 초기화돼 있을 수 있다.
            return FirebaseApp.getInstance();
        }

        try (InputStream in = credentials.getInputStream()) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            log.info("Firebase 초기화 완료 ({})", credentials.getDescription());
            return FirebaseApp.initializeApp(options);
        }
    }

    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp app) {
        return FirebaseMessaging.getInstance(app);
    }
}
