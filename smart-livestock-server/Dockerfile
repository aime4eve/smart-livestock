FROM eclipse-temurin:17-jre
WORKDIR /app

COPY build/libs/smart-livestock-server-*.jar ./

EXPOSE 8080
CMD ["sh", "-c", "exec java -jar smart-livestock-server-*.jar"]
