# 서버 이미지. 빌드와 실행을 나눠서, 최종 이미지에는 JDK도 소스도 남기지 않는다.
# (JDK 이미지는 400MB가 넘는데 실행에는 JRE만 있으면 된다)

### 1단계: 빌드 ###
# gradle:x.y 이미지 대신 temurin + 래퍼를 쓴다. 래퍼가 gradle-wrapper.properties에 적힌
# 버전을 스스로 받아오므로, 여기서 태그를 관리할 필요가 없다.
FROM eclipse-temurin:17-jdk AS build
WORKDIR /workspace

# 의존성 목록만 먼저 복사해서 레이어를 굳힌다.
# 소스만 고친 재빌드에서는 이 아래 RUN이 캐시로 넘어가 라이브러리를 다시 받지 않는다.
COPY gradle gradle
COPY gradlew settings.gradle build.gradle ./
# 윈도우에서 체크아웃하면 실행 권한이 붙지 않는다 (git 인덱스상 100644).
RUN chmod +x gradlew && ./gradlew --no-daemon dependencies > /dev/null 2>&1 || true

COPY src src
# bootJar는 test에 의존하지 않는다. 테스트는 CI/로컬에서 돌리고 이미지 빌드는 짧게 가져간다.
RUN ./gradlew --no-daemon clean bootJar

### 2단계: 실행 ###
FROM eclipse-temurin:17-jre
WORKDIR /app

# 도메인 로직은 ZoneId를 Asia/Seoul로 못 박아 두었지만(DayRange, CalendarPushService),
# 로그 시각과 @Scheduled는 시스템 시간대를 따른다. 컨테이너 기본값은 UTC라 맞춰 준다.
ENV TZ=Asia/Seoul

# root로 돌리지 않는다. 컨테이너가 뚫려도 호스트로 번지는 걸 한 단계 막아 준다.
RUN useradd --system --create-home --shell /usr/sbin/nologin app
USER app

COPY --from=build --chown=app:app /workspace/build/libs/*.jar app.jar

# JVM은 컨테이너 메모리 상한을 인식하지만, 기본값(25%)은 1GB 인스턴스에서 너무 적다.
# 고정 -Xmx 대신 비율로 줘야 인스턴스를 키웠을 때 같이 따라 올라간다.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC"

EXPOSE 8080

# JAVA_OPTS를 단어 분리시켜야 하므로 sh를 거친다.
# exec을 붙여야 java가 PID 1을 물려받아 docker stop의 SIGTERM을 직접 받는다.
# (안 그러면 셸이 신호를 먹고 10초 뒤 강제 종료돼 graceful shutdown이 날아간다)
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
