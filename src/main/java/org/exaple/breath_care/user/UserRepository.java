package org.exaple.breath_care.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailAndDeletedAtIsNull(String email);

    /** 소셜 계정의 열쇠는 이메일이 아니라 provider + providerId다. 이메일은 바뀔 수 있다. */
    Optional<User> findByProviderAndProviderIdAndDeletedAtIsNull(AuthProvider provider, String providerId);

    Optional<User> findByIdAndDeletedAtIsNull(Long id);

    boolean existsByEmailAndDeletedAtIsNull(String email);
}
