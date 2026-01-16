# Enterprise Readiness Guide

This guide upgrades the operational UX for **Agent0** deployments by documenting security integration, compliance expectations, lint/audit routines, and reproducible builds.

## 1. UX / Operational Quality of Life
- **Standardized environment variables**: use a `.env` or secret manager so local and CI setups share the same configuration keys.
- **Clear paths**: keep all runtime artifacts under a single root (e.g., `$STORAGE_PATH`) to simplify cleanup and audits.
- **Runbook-first**: keep the primary workflow in a single script or Make target to reduce tribal knowledge.

### Suggested environment variables
| Variable | Purpose |
| --- | --- |
| `STORAGE_PATH` | Central location for artifacts and checkpoints. |
| `HUGGINGFACENAME` | Hugging Face token or username. |
| `WANDB_API_KEY` | Weights & Biases API key. |
| `SANDBOX_API_URLS` | Comma-separated list of sandbox endpoints for tool execution. |

## 2. Security Integration
- **Secrets management**: load credentials through your enterprise secret manager; avoid `.env` in production.
- **Network policy**: restrict outbound access from training workers to only model, logging, and sandbox endpoints.
- **Artifact integrity**: store checkpoints in immutable object storage with bucket versioning enabled.
- **Sandbox isolation**: treat the sandbox service as untrusted execution; use network isolation and per-request rate limiting.

## 3. Compliance & Audit
- **Data lineage**: log dataset versions, question generation seeds, and filtering thresholds for every training run.
- **Model governance**: keep a manifest with model hash, base model ID, and training configuration.
- **Access control**: enforce RBAC on checkpoints, logs, and sandbox services.
- **Retention**: define retention policies for generated data and intermediate artifacts.

## 4. Linting & Audit Checklist
Use these as baseline checks in CI (adjust for your environment). A `Makefile` target is provided for quick runs.

- **Python linting**: `ruff` or `flake8` for style and static issues.
- **Type checks**: `mypy` for critical modules.
- **Dependency audit**: `pip-audit` or `safety` for known CVEs.
- **License scan**: `pip-licenses` to ensure dependency compliance.

## 5. Build & Release Hygiene
- **Reproducible builds**: pin all dependencies in `requirements.txt` and use a lockfile for CI.
- **Immutable tags**: tag releases with model checkpoint hashes.
- **Container build**: prefer a single base image for all training and evaluation jobs to avoid drift.

### Example CI sequence
```bash
python -m pip install -r requirements.txt
python -m pip install ruff mypy pip-audit pip-licenses
ruff check .
mypy .
pip-audit
pip-licenses --format=markdown
```

### Example local sequence
```bash
python -m pip install ruff mypy pip-audit pip-licenses
make lint
make audit
make build
```

## 6. Suggested Enhancements (Roadmap)
- Add a `Makefile` or `taskfile.yml` with standardized commands (`lint`, `audit`, `train`, `evaluate`).
- Add a `SECURITY.md` with responsible disclosure process and contact info.
- Add CI workflows for linting and dependency audits.
