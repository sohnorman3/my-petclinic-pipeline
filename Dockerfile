# --------------------------------------------------------------------------
# Stage 1: Build the Application
# Uses a reliable OpenJDK 25 image to build the project, meeting the minimum Java 25 requirement.
# --------------------------------------------------------------------------
FROM openjdk:25-jdk AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and project files
# The PetClinic project uses the Maven Wrapper (mvnw) for consistency.
COPY .mvn .mvn
COPY mvnw pom.xml ./

# Pre-download dependencies to leverage Docker layer caching.
# Maven Central is used implicitly here.
RUN ./mvnw dependency:go-offline

# Copy the source code
COPY src ./src

# Compile the code and run the tests.
RUN ./mvnw clean install

# Extract the final JAR filename for use in the next stage
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

# --------------------------------------------------------------------------
# Stage 2: Create the Final Runtime Image
# Uses a lightweight JRE base image for security and size optimization.
# --------------------------------------------------------------------------
FROM openjdk:25-jre-slim-buster

# Expose the port the Spring Boot application runs on
EXPOSE 8080

# Set the working directory
WORKDIR /app

# Copy the built JAR from the 'build' stage
ARG JAR_FILE=target/spring-petclinic-*.jar
COPY --from=build /app/$JAR_FILE app.jar

# Define the entrypoint to run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
