# 1단계: 빌드 스테이지
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

# 종속성 캐싱을 위해 설정 파일 먼저 복사
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# gradlew 실행 권한 부여 및 의존성 미리 다운로드 (캐싱 활용)
RUN chmod +x gradlew
RUN ./gradlew dependencies --no-daemon

# 전체 소스 복사 및 빌드
COPY . .
RUN ./gradlew clean bootJar -x test --no-daemon

# 2단계: 실행 스테이지
# Java 21 버전의 경량화된 Alpine 이미지 사용
FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

# 필요한 패키지 설치
RUN apk add --no-cache ffmpeg

# 환경 변수 설정
ARG PROFILE=dev
ENV SPRING_PROFILES_ACTIVE=${PROFILE}

# 빌드 스테이지에서 생성된 jar 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 임시 디렉토리 생성 및 권한 설정
RUN mkdir -p /app/src/main/resources/temp && \
    chmod -R 755 /app/src/main/resources/temp

EXPOSE 8080

# 실행 명령
ENTRYPOINT ["sh", "-c", "java -jar -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} app.jar"]