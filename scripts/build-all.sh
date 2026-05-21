#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building Cloud Library multi-module project..."
mvn -f pom.xml clean package -DskipTests

echo "Done. JARs:"
echo "  platform/config-server/target/config-server-1.0.0.jar"
echo "  platform/service-registry/target/service-registry-1.0.0.jar"
echo "  platform/api-gateway/target/api-gateway-1.0.0.jar"
echo "  services/member-service/target/member-service-1.0.0.jar"
echo "  services/book-service/target/book-service-1.0.0.jar"
echo "  services/borrowing-service/target/borrowing-service-1.0.0.jar"
