#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SPRING_PROFILES_ACTIVE=native
export CONFIG_SERVER_URL=http://localhost:9000
export EUREKA_URL=http://localhost:9001/eureka/

echo "Starting Config Server (native profile, port 9000)..."
mvn -f platform/config-server/pom.xml spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=native" &
sleep 15

echo "Starting Service Registry (port 9001)..."
mvn -f platform/service-registry/pom.xml spring-boot:run -Dspring-boot.run.jvmArguments="-DCONFIG_SERVER_URL=$CONFIG_SERVER_URL" &
sleep 10

echo "Starting API Gateway (port 8080)..."
mvn -f platform/api-gateway/pom.xml spring-boot:run -Dspring-boot.run.jvmArguments="-DCONFIG_SERVER_URL=$CONFIG_SERVER_URL" &
sleep 8

echo "Starting Member Service..."
mvn -f services/member-service/pom.xml spring-boot:run -Dspring-boot.run.jvmArguments="-DCONFIG_SERVER_URL=$CONFIG_SERVER_URL -Dspring.profiles.active=dev" &
echo "Starting Book Service..."
mvn -f services/book-service/pom.xml spring-boot:run -Dspring-boot.run.jvmArguments="-DCONFIG_SERVER_URL=$CONFIG_SERVER_URL -Dspring.profiles.active=dev" &
echo "Starting Borrowing Service..."
mvn -f services/borrowing-service/pom.xml spring-boot:run -Dspring-boot.run.jvmArguments="-DCONFIG_SERVER_URL=$CONFIG_SERVER_URL -Dspring.profiles.active=dev" &

echo ""
echo "Cloud Library (local):"
echo "  Config Server:      http://localhost:9000"
echo "  Eureka Dashboard:   http://localhost:9001"
echo "  API Gateway:        http://localhost:8080"
