-- 소셜 로그인 도입.
-- 기존 회원은 전부 이메일 가입이므로 LOCAL로 채운다.
ALTER TABLE users
    ADD COLUMN provider    VARCHAR(10)  NOT NULL DEFAULT 'LOCAL',
    ADD COLUMN provider_id VARCHAR(128) NULL;

-- 구글 회원은 비밀번호가 없다.
ALTER TABLE users
    MODIFY COLUMN password VARCHAR(60) NULL;

-- 같은 소셜 계정으로 두 번 가입되지 않게 막는다.
-- LOCAL 회원은 provider_id가 NULL이고, MySQL은 유니크 인덱스에서 NULL 중복을 허용한다.
CREATE UNIQUE INDEX ux_users_provider ON users (provider, provider_id);
