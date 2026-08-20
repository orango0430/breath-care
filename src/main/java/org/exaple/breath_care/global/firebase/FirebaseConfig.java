package org.exaple.breath_care.global.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.util.StringUtils;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Base64;

/**
 * firebase.enabled=true 일 때만 뜬다.
 * 서비스 계정 키가 없는 팀원도 앱을 그대로 실행할 수 있어야 하므로 기본값은 꺼짐이다.
 */
@Configuration
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @Bean
    public FirebaseApp firebaseApp(
            @Value("${firebase.credentials-location:}") String location,
            @Value("${firebase.credentials-base64:}") String base64) throws IOException {

        if (!FirebaseApp.getApps().isEmpty()) {
            // devtools 재시작 시 이미 초기화돼 있을 수 있다.
            return FirebaseApp.getInstance();
        }

        try (InputStream in = openCredentials(location, base64)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            FirebaseApp app = FirebaseApp.initializeApp(options);

            // 어느 프로젝트의 키인지 남긴다. 앱의 google-services.json과 프로젝트가
            // 다르면 소셜 로그인이 전부 INVALID_SOCIAL_TOKEN으로 떨어지는데, 그때
            // 로그에 이 줄이 없으면 원인을 좁힐 방법이 없다.
            log.info("Firebase 프로젝트: {}", app.getOptions().getProjectId());
            return app;
        }
    }

    /**
     * 자격증명을 base64 환경변수 또는 파일에서 읽는다. base64가 있으면 그쪽을 먼저 쓴다.
     *
     * <p>둘 다 받는 이유는 배포처마다 비밀값을 주는 방식이 다르기 때문이다.
     * Railway 같은 PaaS는 <b>환경변수만</b> 주고 파일을 올려 둘 곳이 없다.
     * 반대로 로컬과 EC2에서는 파일을 볼륨으로 물리는 쪽이 편하다.
     * 한쪽만 지원하면 배포처를 옮길 때마다 이 클래스를 고쳐야 한다.
     */
    private InputStream openCredentials(String location, String base64) throws IOException {
        if (StringUtils.hasText(base64)) {
            log.info("Firebase 자격증명을 환경변수(base64)에서 읽습니다.");
            // getDecoder()는 줄바꿈이 섞이면 그대로 터진다. base64 명령이 76자마다 줄을 접는 데다
            // 콘솔에 붙여 넣는 과정에서도 공백이 들어가기 쉬워서, 관대한 쪽을 쓴다.
            return new ByteArrayInputStream(Base64.getMimeDecoder().decode(base64));
        }

        if (StringUtils.hasText(location)) {
            Resource resource = resourceLoader.getResource(location);
            log.info("Firebase 자격증명을 파일에서 읽습니다. ({})", resource.getDescription());
            return resource.getInputStream();
        }

        // 여기서 앱을 죽이는 게 맞다. 그냥 뜨면 푸시와 소셜 로그인이 런타임에 조용히 실패한다.
        throw new IllegalStateException("firebase.enabled=true인데 자격증명이 없습니다. "
                + "FIREBASE_CREDENTIALS(파일 경로) 또는 FIREBASE_CREDENTIALS_BASE64 중 하나를 설정하세요.");
    }

    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp app) {
        return FirebaseMessaging.getInstance(app);
    }

    /** 소셜 로그인 토큰 검증에 쓴다. */
    @Bean
    public FirebaseAuth firebaseAuth(FirebaseApp app) {
        return FirebaseAuth.getInstance(app);
    }
}
