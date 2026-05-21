# Deprecated — use Config Server native layouts

External configuration now lives in:

`platform/config-server/src/main/resources/configurations/`

For GCP production, copy the same `platform/` and `services/` YAML files into
[ChamathDilshanC/Cafeteria-System-Configurations](https://github.com/ChamathDilshanC/Cafeteria-System-Configurations)
(or a dedicated cloud-library config repo) so the Config Server `git` profile can serve them.
