# Config Server setup

## External Git repository (GCP / production)

The config server loads YAML from:

https://github.com/ChamathDilshanC/Cafeteria-System-Configurations

Configured in `platform/config-server/src/main/resources/application.yml`:

- `spring.cloud.config.server.git.uri` — repository URL
- `search-paths: platform,services` — matches repo layout
- `default-label: main`

**Action required:** Add Cloud Library YAML files to that repo (same paths as local `configurations/`), for example:

- `platform/api-gateway.yaml`
- `platform/service-registry.yaml`
- `services/member-service.yaml`
- `services/book-service.yaml`
- `services/borrowing-service.yaml`

Until those files exist in Git, use the `native` profile on the VM or keep a local clone.

## Local development (native profile)

Local configs mirror the Git layout under:

`platform/config-server/src/main/resources/configurations/`

Run config server:

```bash
mvn -f platform/config-server/pom.xml spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=native"
```

Or use `scripts/run-local.sh`, which sets `SPRING_PROFILES_ACTIVE=native`.

## GCP environment variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `CONFIG_SERVER_URL` | `http://10.0.0.10:9000` | Internal IP of config-server VM |
| `CONFIG_SERVER_PROFILE` | `git` | Config server backend on platform VM |
| `EUREKA_URL` | `http://10.0.0.11:9001/eureka/` | Service registry internal URL |

See `docs/env-template.sh` for a full template.

## Startup order

1. **config-server** (port 9000)
2. **service-registry** (port 9001)
3. **api-gateway** (port 8080)
4. **member-service**, **book-service**, **borrowing-service**
