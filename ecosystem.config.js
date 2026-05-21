/**
 * PM2 — full stack (platform + business services).
 * Set CONFIG_SERVER_URL / EUREKA_URL to VM internal IPs on GCP.
 *
 *   pm2 start ecosystem.config.js
 *   pm2 save && pm2 startup
 */
const CONFIG_SERVER = process.env.CONFIG_SERVER_URL || 'http://localhost:9000';
const EUREKA = process.env.EUREKA_URL || 'http://localhost:9001/eureka/';

module.exports = {
  apps: [
    {
      name: 'config-server',
      script: 'java',
      args: '-jar platform/config-server/target/config-server-1.0.0.jar',
      env: {
        SPRING_PROFILES_ACTIVE: process.env.CONFIG_SERVER_PROFILE || 'git',
      },
      log_file: './logs/config-server.log',
    },
    {
      name: 'service-registry',
      script: 'java',
      args: `-jar platform/service-registry/target/service-registry-1.0.0.jar --spring.config.import=configserver:${CONFIG_SERVER}`,
      env: {
        CONFIG_SERVER_URL: CONFIG_SERVER,
        EUREKA_URL: EUREKA,
      },
      log_file: './logs/service-registry.log',
    },
    {
      name: 'api-gateway',
      script: 'java',
      args: `-jar platform/api-gateway/target/api-gateway-1.0.0.jar --spring.config.import=configserver:${CONFIG_SERVER}`,
      env: {
        CONFIG_SERVER_URL: CONFIG_SERVER,
        EUREKA_URL: EUREKA,
      },
      log_file: './logs/api-gateway.log',
    },
    {
      name: 'member-service',
      script: 'java',
      args: `-jar services/member-service/target/member-service-1.0.0.jar --spring.config.import=configserver:${CONFIG_SERVER}`,
      env: {
        CONFIG_SERVER_URL: CONFIG_SERVER,
        EUREKA_URL: EUREKA,
      },
      log_file: './logs/member-service.log',
      instances: 1,
    },
    {
      name: 'book-service',
      script: 'java',
      args: `-jar services/book-service/target/book-service-1.0.0.jar --spring.config.import=configserver:${CONFIG_SERVER}`,
      env: {
        CONFIG_SERVER_URL: CONFIG_SERVER,
        EUREKA_URL: EUREKA,
      },
      log_file: './logs/book-service.log',
      instances: 1,
    },
    {
      name: 'borrowing-service',
      script: 'java',
      args: `-jar services/borrowing-service/target/borrowing-service-1.0.0.jar --spring.config.import=configserver:${CONFIG_SERVER}`,
      env: {
        CONFIG_SERVER_URL: CONFIG_SERVER,
        EUREKA_URL: EUREKA,
      },
      log_file: './logs/borrowing-service.log',
      instances: 1,
    },
  ],
};
