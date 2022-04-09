FROM maven:3.8.5-openjdk-17 as builder

# Go to usr/local/app and copy files into it
WORKDIR /usr/local/app
COPY . ./

RUN mvn -Dmaven.test.skip=true package

FROM openjdk:17.0
WORKDIR /usr/local/app
COPY --from=builder /usr/local/app/target/montecito-1.0-SNAPSHOT-jar-with-dependencies.jar ./montecito.jar

CMD [ "java", "-jar", "montecito.jar" ]