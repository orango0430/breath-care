package org.exaple.breath_care.measurement;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.StringJoiner;

/**
 * 거부된 파형을 남긴다. 알고리즘을 고칠 근거가 여기서만 나온다.
 *
 * <p><b>별도 빈으로 둔 이유는 트랜잭션 때문이다.</b> {@code measure()}는 트랜잭션 안에서
 * 돌고 거부는 예외로 끝나므로, 같은 트랜잭션에 저장하면 롤백과 함께 사라진다. 남기려는
 * 대상이 예외 상황이니 예외에 딸려 사라지면 의미가 없다. 그래서 새 트랜잭션에서 쓴다.
 * 자기 호출(self-invocation)로는 프록시를 타지 않으므로 클래스도 분리해야 한다.
 */
@Component
@RequiredArgsConstructor
public class RejectedSignalRecorder {

    private static final Logger log = LoggerFactory.getLogger(RejectedSignalRecorder.class);

    /** 이보다 짧은 파형은 남겨도 배울 게 없다. 손가락을 대자마자 뗀 경우다. */
    private static final int MIN_WORTH_KEEPING = 50;

    private final RejectedSignalRepository repository;

    /**
     * @param userId 비회원이면 null
     * @param reason 어느 게이트에 걸렸는지
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(Long userId, int fps, int durationSec,
                       List<Double> samples, String reason) {
        if (samples == null || samples.size() < MIN_WORTH_KEEPING) {
            return;
        }

        try {
            repository.save(new RejectedSignal(
                    userId, fps, durationSec, samples.size(), reason, join(samples)));
        } catch (RuntimeException e) {
            // 기록에 실패했다고 사용자 응답까지 바꾸지는 않는다. 어차피 재측정 안내가 나간다.
            log.warn("거부된 파형을 남기지 못했습니다: {}", e.getMessage());
        }
    }

    private String join(List<Double> samples) {
        StringJoiner joiner = new StringJoiner(",");
        samples.forEach(value -> joiner.add(String.valueOf(value)));
        return joiner.toString();
    }
}
