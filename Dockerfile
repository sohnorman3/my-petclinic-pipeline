# --------------------------------------------------------------------------
# Stage 1: Build the Application
# Uses an OpenJDK image with Maven installed to build the project.
# --------------------------------------------------------------------------
# Updated to temurin-25 to meet the project's requirement (Java 25+)
FROM maven:3.9.6-eclipse-temurin-25 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and project files
COPY .mvn .mvn
COPY mvnw pom.xml ./

# Pre-download dependencies to leverage Docker layer caching.
# This ensures that only pom.xml changes trigger a full dependency download.
# Maven Central is used implicitly here.
RUN ./mvnw dependency:go-offline

# Copy the source code
COPY src ./src

# Compile the code and run the tests. 
# '-DTests' is removed here to ensure tests run during the build stage.
# The 'install' phase executes compile, test, and package goals.
RUN ./mvnw clean install

# Extract the final JAR filename for use in the next stage
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

# --------------------------------------------------------------------------
# Stage 2: Create the Final Runtime Image
# Uses a lightweight JRE base image for security and size optimization.
# --------------------------------------------------------------------------
# Updated to JRE 25 for consistency and modern environment
FROM eclipse-temurin:25-jre-focal

# Set a non-root user for security best practices (Spring Boot app runs on 8080)
# Note: The PetClinic app is designed to run in a typical Linux environment.
# User configuration is omitted for simplicity, but best practice is to define one.

# Expose the port the Spring Boot application runs on
EXPOSE 8080

# Set the working directory
WORKDIR /app

# Copy the built JAR from the 'build' stage
# The JAR file is typically named 'spring-petclinic-{version}.jar'
ARG JAR_FILE=target/spring-petclinic-*.jar
COPY --from=build /app/$JAR_FILE app.jar

# Define the entrypoint to run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
