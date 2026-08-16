package org.exaple.breath_care.user.social;

import org.exaple.breath_care.global.exception.BusinessException;
import org.exaple.breath_care.global.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Firebase 키 없이 서버를 띄웠을 때 대신 들어가는 구현.
 *
 * <p>키가 없다고 앱이 아예 뜨지 않으면 팀원이 개발을 못 한다. 대신 소셜 로그인만
 * 명확한 오류로 막고, 자체 로그인과 비회원 이용은 그대로 되게 둔다.
 */
@Component
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "false", matchIfMissing = true)
public class DisabledSocialTokenVerifier implements SocialTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(DisabledSocialTokenVerifier.class);

    @Override
    public SocialAccount verify(String idToken) {
        log.warn("Firebase가 꺼져 있어 소셜 로그인을 처리할 수 없습니다. (firebase.enabled=false)");

        throw new BusinessException(ErrorCode.SOCIAL_LOGIN_UNAVAILABLE);
    }
}
