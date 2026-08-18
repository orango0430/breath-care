# 배포

배포처는 **AWS Elastic Beanstalk** (Docker running on 64bit Amazon Linux 2023, 단일 인스턴스)다.
같은 `Dockerfile`로 로컬 검증도 하므로 배포처가 바뀌어도 코드는 그대로다.

---

## 1. Elastic Beanstalk

### 왜 이 구성인가

- **단일 인스턴스** — 로드밸런서를 붙이면 ALB 요금이 매달 따로 나간다(프리티어 아님).
  APK가 서버 주소에 직접 붙는 구조라 지금은 쓸 데가 없다.
- **Dockerfile 단독 배포** — `docker-compose.yml`을 번들에 넣지 않는다. 아래 참고.
- **DB는 EB 밖의 RDS** — EB가 만들어 주는 DB는 환경을 지우면 **같이 지워진다.**
  따로 만들어 두고 주소만 넘긴다.

### 함정 두 가지

**(1) `docker-compose.yml`이 번들에 들어가면 안 된다.**
번들 최상위에 이 파일이 있으면 EB는 Compose 모드로 전환해서 `Dockerfile`을 무시하고
개발용 스택(MySQL 포함, 포트 3307)을 띄우려 한다. `.ebignore`가 이걸 막는다.

`.ebignore`가 있으면 EB CLI는 **`.gitignore`를 아예 보지 않는다.** 그래서 커밋 금지 파일도
`.ebignore`에 다시 적어 뒀다. 이 파일에서 뭘 지울 때는 그 점을 기억해야 한다.

**(2) 환경 속성은 전부 합쳐 4,096바이트를 넘을 수 없다.**
넘으면 오류를 내지 않고 **조용히 저장에 실패한다.** 현재 예산:

| 속성 | 바이트 |
|---|---:|
| `FIREBASE_CREDENTIALS_BASE64` | 3,217 |
| `OPENAI_API_KEY` | 180 |
| `DB_URL` | ~117 |
| `.ebextensions`의 5개 | 104 |
| `JWT_SECRET` | 76 |
| `DB_PASSWORD` | 37 |
| `DB_USERNAME` | 20 |
| **합계** | **~3,751 / 4,096** |

여유가 345바이트뿐이다. 속성을 더 넣어야 하면 먼저 재 보고,
모자라면 Firebase 키를 Secrets Manager나 SSM 파라미터 스토어로 빼야 한다
(EB 콘솔의 환경 변수 **Source**에서 고를 수 있다).

### 절차

**1) RDS를 먼저 만든다** — MySQL, `db.t3.micro`, 20GB, 서울 리전.
퍼블릭 액세스는 끄고, 보안 그룹은 EB 인스턴스의 보안 그룹에서 오는 3306만 연다.

**2) 애플리케이션과 환경을 만든다**

```bash
eb init --platform docker --region ap-northeast-2 breath-care
eb create breath-care-prod --single --instance-type t3.micro
```

`--single`을 빼면 로드밸런서가 붙어 요금이 나간다. `.ebextensions/01-options.config`에도
같은 설정이 들어 있지만, 환경을 만드는 시점의 인자가 우선이라 여기서도 지정한다.

**3) 비밀값을 넣는다**

```bash
eb setenv \
  DB_URL="jdbc:mysql://<rds-endpoint>:3306/breathcare?characterEncoding=UTF-8&serverTimezone=Asia/Seoul" \
  DB_USERNAME=admin \
  DB_PASSWORD='...' \
  JWT_SECRET='...' \
  OPENAI_API_KEY='...' \
  FIREBASE_CREDENTIALS_BASE64="$(base64 -w0 firebase-service-account.json)"
```

EB에는 파일을 물릴 볼륨이 없어서 Firebase 키는 base64 환경변수로 넣는다.
`FirebaseConfig`가 파일 경로와 base64를 둘 다 받으므로 코드는 손댈 필요가 없다.
(`Base64.getMimeDecoder()`를 쓰기 때문에 줄바꿈이 섞여도 괜찮다.)

**4) 배포하고 확인한다**

```bash
eb deploy
eb open
```

- Flyway 13개 적용 — `eb logs`에서 확인
- `GET /api/breathing/presets` → 200
- `POST /api/auth/signup` → 201, `POST /api/auth/login` → 200
- 토큰 없이 `GET /api/calendar/events` → 401

### 포트

EB의 nginx는 `Dockerfile`의 **첫 `EXPOSE`** 포트로 연결한다. 우리는 8080이다.
앱은 `server.port: ${PORT:8080}`이라 `PORT`가 없으면 8080에 붙지만,
플랫폼이 다른 값을 넣을 여지를 없애려고 `.ebextensions`에서 `PORT=8080`으로 고정했다.

---

## 2. 로컬 · EC2 (Docker Compose)

EB를 쓰지 않고 서버 한 대에 통째로 띄울 때 쓴다. MySQL도 같이 올라간다.

```bash
cp .env.prod.example .env.prod          # 값을 채운다
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

이쪽은 `firebase-service-account.json`을 파일로 물리므로 base64가 필요 없다.
파일을 `.env.prod`와 같은 폴더에 두면 된다.

---

## 3. 프리티어 주의

- 프리티어는 **계정당 12개월 한 번뿐이다.** 이미 쓴 계정이면 EC2와 RDS 모두 과금된다.
- EB 자체는 무료다. 요금은 그 아래 EC2·EBS·RDS에서 나온다.
- 환경을 안 쓸 때는 `eb terminate`로 지운다. RDS는 EB 밖에 있으므로 함께 지워지지 않는다.
