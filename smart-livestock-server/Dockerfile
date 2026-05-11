# Stage 1: Build
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

COPY build.gradle settings.gradle gradle.properties ./
COPY gradle ./gradle
COPY gradlew ./
RUN ./gradlew dependencies --no-daemon || true

COPY src ./src
RUN ./gradlew bootJar --no-daemon

# Stage 2: Run
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
