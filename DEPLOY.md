# 배포

배포처는 **Railway**다. 같은 `Dockerfile`로 로컬 검증도 하므로 배포처가 바뀌어도 코드는 그대로다.

한 번 AWS Elastic Beanstalk로 옮겼다가 되돌렸다. 이유는 아래 "왜 Railway인가"에 적어 둔다.

---

## 1. Railway

### 왜 Railway인가

- **빌드를 Railway 빌더가 한다.** EB는 배포 대상 인스턴스(t3.micro, 2 vCPU / 1GB)에서
  직접 그래들 빌드를 돌리는데 16분이 걸려 배포 명령이 타임아웃으로 잘렸다.
  Railway는 빌드 머신이 따로라 `Dockerfile` 그대로 멀티스테이지 빌드가 돈다.
- **관리할 게 없다.** EB는 RDS·보안 그룹·IAM·환경 속성 4KB 제한을 전부 손으로 맞춰야 했다.
- **DB가 한 클릭이다.** 같은 프로젝트에 MySQL을 붙이면 내부 네트워크로 바로 붙는다.
- 요금은 Hobby 플랜 월 $5(사용량 크레딧 $5 포함). 해커톤 규모에서는 이 안에 들어온다.

### 절차

**1) 프로젝트를 만들고 저장소를 연결한다**

Railway 대시보드 → New Project → Deploy from GitHub repo → `orango0430/breath-care`.
브랜치는 `main`. 이후 `main`에 푸시할 때마다 자동으로 다시 배포된다.

`railway.json`이 이미 저장소에 있어서 빌더(`DOCKERFILE`)와 헬스체크 경로는 따로 고를 필요가 없다.

**2) MySQL을 붙인다**

같은 프로젝트 안에서 New → Database → **Add MySQL**.
DB가 프로젝트 밖에 있으면 인터넷을 한 바퀴 돌아 지연이 붙으므로 반드시 같은 프로젝트에 둔다.

**3) 변수를 넣는다** (앱 서비스 → Variables)

DB 값은 직접 적지 않고 MySQL 서비스를 **참조**한다. 비밀번호가 바뀌어도 따라간다.

```
DB_URL       = jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?characterEncoding=UTF-8&serverTimezone=Asia/Seoul
DB_USERNAME  = ${{MySQL.MYSQLUSER}}
DB_PASSWORD  = ${{MySQL.MYSQLPASSWORD}}

SPRING_PROFILES_ACTIVE = prod
JWT_SECRET             = (openssl rand -base64 48)
REPORT_PROVIDER        = openai
OPENAI_API_KEY         = (LikeLionDGU 조직 키)
OPENAI_MODEL           = gpt-5.4-mini
FIREBASE_ENABLED       = true
FIREBASE_CREDENTIALS_BASE64 = (아래 참고)
```

`PORT`는 **넣지 않는다.** Railway가 자기 값을 주입하고 앱은 `${PORT:8080}`으로 받는다.
직접 고정하면 Railway가 붙는 포트와 어긋나 헬스체크가 죽는다.

Firebase 키는 파일을 둘 데가 없으므로 base64 한 줄로 넣는다:

```bash
base64 -w0 firebase-service-account.json
```

`FirebaseConfig`가 파일 경로와 base64를 둘 다 받으므로 코드는 손댈 필요가 없다.
(`Base64.getMimeDecoder()`를 쓰기 때문에 줄바꿈이 섞여도 괜찮다.)

**4) 도메인을 연다**

앱 서비스 → Settings → Networking → **Generate Domain**.
`***.up.railway.app` 주소가 나오고 HTTPS가 자동으로 붙는다.
이 주소를 프론트의 `baseUrl`에 넣는다. HTTPS라 안드로이드 cleartext 예외도 필요 없다.

**5) 확인한다**

```bash
BASE=https://<생성된-도메인>

curl -s $BASE/api/breathing/presets | head -c 200          # 200
curl -s -o /dev/null -w '%{http_code}\n' $BASE/api/calendar/events   # 401
```

- Flyway 13개 적용 — Deployments → 로그에서 확인
- `POST /api/auth/signup` → 201, `POST /api/auth/login` → 200

### 걸리는 곳

**내부 DB 주소는 IPv6다.** Railway의 사설 네트워크(`*.railway.internal`)는 IPv6만 쓴다.
JVM이 IPv4를 먼저 찾다 연결에 실패하면 앱 서비스 변수에 이걸 추가한다:

```
JAVA_TOOL_OPTIONS = -Djava.net.preferIPv4Stack=false
```

**첫 배포는 5~10분 걸린다.** 그래들 의존성을 처음부터 받기 때문이다.
두 번째부터는 레이어 캐시가 살아서 훨씬 짧다. `railway.json`의
`healthcheckTimeout: 180`은 기동 시간(Flyway 포함)을 감안한 값이다.

**빌드 컨텍스트는 `.dockerignore`를 따른다.** `frontend/`, `build/`, 비밀 파일이 여기서 걸린다.
`.env*`와 `firebase-service-account.json`은 절대 이미지에 굽지 않는다 — 레이어에 남는다.

---

## 2. 로컬 검증 (Docker Compose)

배포 전에 같은 이미지가 실제로 뜨는지 여기서 본다. MySQL도 같이 올라간다.

```bash
cp .env.prod.example .env.prod          # 값을 채운다
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

이쪽은 `firebase-service-account.json`을 파일로 물리므로 base64가 필요 없다.
파일을 `.env.prod`와 같은 폴더에 두면 된다.

---

## 3. 요금

- Hobby 플랜 월 $5에 사용량 크레딧 $5가 포함된다. 앱 + MySQL 두 서비스가 상시로 돌면
  이 안에서 끝나지만, 트래픽이 튀면 초과분은 따로 청구된다.
- 안 쓸 때는 서비스를 **Remove**가 아니라 **Pause**로 세워 두면 과금이 멈춘다.
  Remove하면 MySQL 볼륨까지 사라진다.
- 사용량은 대시보드 → Usage에서 실시간으로 본다. 해커톤 전날 한 번 확인해 둔다.
