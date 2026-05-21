@echo off
echo Building all services (requires JDK 25 + Maven 4.0+)...

call mvn -f ..\platform\config-server\pom.xml -DskipTests clean package
echo [1/6] Config Server built.

call mvn -f ..\platform\eureka-server\pom.xml -DskipTests clean package
echo [2/6] Eureka Server built.

call mvn -f ..\platform\api-gateway\pom.xml -DskipTests clean package
echo [3/6] API Gateway built.

call mvn -f ..\services\member-service\pom.xml -DskipTests clean package
echo [4/6] Member Service built.

call mvn -f ..\services\book-service\pom.xml -DskipTests clean package
echo [5/6] Book Service built.

call mvn -f ..\services\borrowing-service\pom.xml -DskipTests clean package
echo [6/6] Borrowing Service built.


echo.
echo All builds completed successfully!
