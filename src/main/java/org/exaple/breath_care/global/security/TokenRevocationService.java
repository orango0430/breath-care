package org.exaple.breath_care.global.security;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class TokenRevocationService {

    private static final Logger log = LoggerFactory.getLogger(TokenRevocationService.class);

    private final RevokedTokenRepository revokedTokenRepository;

    @Transactional
    public void revoke(String jti, Instant expiresAt) {
        // 같은 토큰으로 로그아웃을 두 번 호출해도 실패하지 않게 한다.
        if (!revokedTokenRepository.existsById(jti)) {
            revokedTokenRepository.save(new RevokedToken(jti, expiresAt));
        }
    }

    @Transactional(readOnly = true)
    public boolean isRevoked(String jti) {
        return revokedTokenRepository.existsById(jti);
    }

    /** 이미 만료된 토큰은 목록에 남겨둘 이유가 없다. 매시 정각에 정리한다. */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void purgeExpired() {
        int deleted = revokedTokenRepository.deleteExpired(Instant.now());
        if (deleted > 0) {
            log.info("만료된 무효화 토큰 {}건 정리", deleted);
        }
    }
}
