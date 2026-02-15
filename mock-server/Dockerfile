FROM eclipse-temurin:17-jdk AS build

WORKDIR /app
COPY build.gradle ./
COPY src/ src/

RUN echo 'rootProject.name = "salesforce-mock-server"' > settings.gradle && \
    apt-get update && apt-get install -y --no-install-recommends wget unzip && \
    wget -q https://services.gradle.org/distributions/gradle-8.11.1-bin.zip -O /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    rm /tmp/gradle.zip && \
    ln -s /opt/gradle-8.11.1/bin/gradle /usr/local/bin/gradle && \
    gradle shadowJar --no-daemon

FROM eclipse-temurin:17-jre

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/libs/salesforce-mock-server-1.0.0.jar /app/mock-server.jar

ENV SERVER_PORT=8089
EXPOSE 8089

CMD ["java", "-jar", "/app/mock-server.jar"]
