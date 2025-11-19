Spring PetClinic CI/CD Pipeline using GitHub Actions and JFrog Artifactory

This repository contains the necessary files (ci-cd.yml and Dockerfile) to implement a Continuous Integration and Continuous Delivery (CI/CD) pipeline for the Spring PetClinic application.

⚙️ Pipeline Overview

The GitHub Actions workflow automates the following steps:

Build & Test: Compiles the code using Java 21 LTS (bypassing the project's strict Java 25 requirement via Maven flags).

Package: Builds a runnable Docker image using a multi-stage build with Eclipse Temurin 21 JRE.

Authentication: Logs into the JFrog Artifactory Docker registry using GitHub Secrets.

Publish: Pushes the Docker image and Build Info to Artifactory.

Scan & Gate: Triggers a security scan via JFrog Xray and fails the pipeline if violations are found.

🚀 Setup and Prerequisites
1. JFrog Artifactory Configuration (Mandatory)

These steps must be performed manually in the JFrog Platform UI:

Create a Docker Repository

Create a Local Repository

Type: Docker

Repository Key: petclinic-docker-local

Configure Xray Watch

Create an Xray Watch

Assign a Security Policy

Under Resources, include builds matching:

petclinic-docker-build*

2. GitHub Secrets Configuration (CRITICAL)

Add these repository secrets under GitHub → Settings → Secrets → Actions.

Secret Name	Description	Example / Format
JFROG_PLATFORM_URL	Full JFrog root URL	https://my-instance.jfrog.io
JFROG_USERNAME	Your JFrog username or email	(string)
JFROG_ACCESS_TOKEN	Scoped Access Token with:
• Repo Read/Write
• Manage Builds	(token)
🛠️ Technical Workarounds Implemented

Due to constraints in PetClinic and JFrog SaaS trial environments:

✔ Java Version Override

The project enforces Java 25+, but stable JDK 25 images are unavailable.
Pipeline compiles using Java 21, bypassing enforcer rules:

-Dmaven.enforcer.skip=true

✔ JFrog CLI Authentication Fix

The workflow manually configures the JFrog CLI using:

jf c add


This bypasses URL/protocol parsing failures commonly seen in JFrog trial SaaS instances.

🐳 Running the Docker Image Locally

After the CI/CD pipeline pushes your Docker image, follow these steps:

1. Set Local Environment Variables

Replace the bracket placeholders with your actual values.

# Your JFrog Instance Details
JFROG_URL="[YOUR_JFROG_PLATFORM_URL_HERE]" # Example: https://trial******.jfrog.io
DOCKER_REPO="petclinic-docker-local"
IMAGE_NAME="spring-petclinic"

# Must match the tag from the successful pipeline run
IMAGE_TAG="[LATEST-IMAGE-TAG]"

# Final image path for Docker
FULL_IMAGE_PATH="${JFROG_URL}/${DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

# Your Artifactory Credentials
JFROG_USER="[YOUR-JFROG-USERNAME]"
JFROG_PASS="[YOUR-JFROG-ACCESS-TOKEN]"

2. Login, Pull, and Run the Image
# A. Log in to the Artifactory Docker registry
# Strips protocol to obtain the host (e.g., trialgwqvmt.jfrog.io)
REGISTRY_HOST=$(echo $JFROG_URL | sed 's|^https://||' | sed 's|/$||')
echo $JFROG_PASS | docker login $REGISTRY_HOST -u $JFROG_USER --password-stdin

# B. Pull the image
docker pull $FULL_IMAGE_PATH

# C. Run the application
docker run -d -p 8080:8080 --name petclinic-app $FULL_IMAGE_PATH

echo "PetClinic is running! Access it at http://localhost:8080"


