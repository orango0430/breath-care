package org.exaple.breath_care.user;

/**
 * 계정을 만든 경로.
 *
 * <p>비회원은 여기에 없다. 서버에 계정을 만들지 않기 때문이다.
 */
public enum AuthProvider {

    /** 이메일 + 비밀번호로 직접 가입. */
    LOCAL,

    /** 구글 계정. 비밀번호가 없다. */
    GOOGLE
}
