FROM eclipse-temurin:17-jre
WORKDIR /app

COPY build/libs/smart-livestock-server-*.jar ./

# Pick the highest version jar (sort -V: 0.2.1-b91 > 0.2.1-b90, 0.2.2-b1 > 0.2.1-b91)
RUN latest=$(ls smart-livestock-server-*.jar | sort -V | tail -1) && \
    mv "$latest" app.jar && \
    rm -f smart-livestock-server-*.jar

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
