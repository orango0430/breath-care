package org.exaple.breath_care.global.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
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
            @Value("${firebase.credentials-base64:}") String base64,
            @Value("${firebase.project-id:}") String configuredProjectId) throws IOException {

        if (!FirebaseApp.getApps().isEmpty()) {
            // devtools 재시작 시 이미 초기화돼 있을 수 있다.
            return FirebaseApp.getInstance();
        }

        try (InputStream in = openCredentials(location, base64)) {
            GoogleCredentials credentials = GoogleCredentials.fromStream(in);
            String projectId = resolveProjectId(configuredProjectId, credentials);

            FirebaseOptions.Builder builder = FirebaseOptions.builder()
                    .setCredentials(credentials);

            // 프로젝트 id를 반드시 박아 둔다.
            //
            // verifyIdToken은 토큰의 aud가 이 프로젝트인지 봐야 하므로 project id 없이는
            // 아예 동작하지 않는다. SDK는 setProjectId가 비어 있으면 서비스 계정 키에서
            // 꺼내 보고, 그것도 아니면 GOOGLE_CLOUD_PROJECT 환경변수를 보는데, 서비스
            // 계정이 아닌 자격증명(gcloud 사용자 키 등)이 들어오면 셋 다 실패해서
            // 소셜 로그인이 전부 INVALID_SOCIAL_TOKEN으로 떨어진다.
            if (StringUtils.hasText(projectId)) {
                builder.setProjectId(projectId);
            }

            FirebaseApp app = FirebaseApp.initializeApp(builder.build());

            log.info("Firebase 초기화 완료. 자격증명={}, 프로젝트={}",
                    credentials.getClass().getSimpleName(), projectId);

            if (!StringUtils.hasText(projectId)) {
                // 여기서 죽이지는 않는다. 푸시는 자격증명만으로 되는 경우가 있어
                // 서버 전체를 못 뜨게 할 이유는 없다. 대신 크게 남긴다.
                log.error("Firebase 프로젝트 id를 알 수 없습니다. 소셜 로그인이 전부 실패합니다. "
                        + "서비스 계정 키가 맞는지 확인하거나 FIREBASE_PROJECT_ID를 설정하세요.");
            }
            return app;
        }
    }

    /**
     * 설정값 → 서비스 계정 키 안의 project_id 순으로 찾는다.
     *
     * <p>설정값을 먼저 보는 이유는, 키가 잘못 들어갔을 때 키를 다시 발급받지 않고도
     * 환경변수 하나로 되살릴 수 있어야 하기 때문이다.
     */
    private String resolveProjectId(String configured, GoogleCredentials credentials) {
        if (StringUtils.hasText(configured)) {
            return configured.trim();
        }
        if (credentials instanceof ServiceAccountCredentials serviceAccount) {
            return serviceAccount.getProjectId();
        }
        return null;
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
