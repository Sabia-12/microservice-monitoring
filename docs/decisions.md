# Architecture Decision Records (ADR)

This document records significant architectural and technology decisions made during
the project. Each entry follows a lightweight ADR format: **Context → Decision → Rationale → Consequences**.

---

## ADR-001 · Python 3.14 for all backend and ML code

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
The project requires a modern runtime for data science (NumPy, Pandas, scikit-learn) and async web serving (FastAPI). The developer machine has Python 3.14.0 installed.

**Decision**  
Use Python 3.14 (the version available on the developer machine). Pin all package versions in `requirements.txt`.

**Rationale**  
- All key packages (scikit-learn 1.8, FastAPI 0.162, pandas 3.0, NumPy 2.3) publish 3.14-compatible wheels on PyPI — no source compilation required.
- Python 3.14 introduces interpreter-level improvements (free-threaded mode experimental, improved error messages).

**Consequences**  
- Cloud deployment images must use a `python:3.14-slim` base.
- Contributors need Python 3.14+; document this in README.

---

## ADR-002 · FastAPI + Uvicorn as the REST API framework

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Need an async Python HTTP framework to expose detection results, serve alerts, and stream live updates via SSE.

**Decision**  
Use FastAPI (v0.162) with Uvicorn (v0.54) as the ASGI server.

**Rationale**  
- Automatic OpenAPI / Swagger UI generation — critical for frontend contract alignment.
- Native `async/await` — essential for SSE streaming without blocking.
- Pydantic v2 integration provides schema validation and serialisation out of the box.
- Significantly less boilerplate than Django REST Framework; lighter than Flask for async use-cases.

**Consequences**  
- All route handlers must be `async def` to avoid blocking the event loop.
- No Django ORM; SQLAlchemy chosen separately (ADR-003).

---

## ADR-003 · SQLite for development, PostgreSQL-ready via SQLAlchemy

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Need persistent storage for ingested metrics, anomaly events, and alert records. Development must work without a running database server.

**Decision**  
Use SQLAlchemy (async Core) with SQLite as the development backend. Switch to PostgreSQL in production by changing `DATABASE_URL` only.

**Rationale**  
- Zero-config local dev (SQLite file in repo root, gitignored).
- SQLAlchemy async engine (`asyncpg` driver) supports PostgreSQL with no model changes.
- Alembic (installed as a dev dependency) will manage migrations.

**Consequences**  
- Must avoid SQLite-specific SQL features (e.g., `RETURNING` is supported in SQLite ≥ 3.35 — acceptable).
- Connection pool settings must be tuned for PostgreSQL in the deployment config.

---

## ADR-004 · React + Vite (TypeScript) for the frontend dashboard

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Need a reactive dashboard that displays time-series anomaly charts and a live alert feed.

**Decision**  
Scaffold with `npm create vite@latest -- --template react-ts`. Use TypeScript throughout.

**Rationale**  
- Vite's HMR is far faster than CRA for iterative development.
- TypeScript enables generating typed API clients from FastAPI's OpenAPI schema (future: `openapi-typescript-codegen`).
- No SSR required, so Next.js overhead is unwarranted.

**Consequences**  
- All components in `.tsx`; strict mode enabled in `tsconfig.json`.
- API base URL read from `VITE_API_BASE_URL` env var (Vite exposes `VITE_*` to the browser bundle).

---

## ADR-005 · Recharts for time-series and anomaly visualisation

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Need composable, React-native charting for multi-metric time-series with anomaly overlays.

**Decision**  
Use Recharts (React-native SVG charts).

**Rationale**  
- Built for React — no imperative D3 lifecycle management.
- `ComposedChart` lets us overlay scatter-plot anomaly markers on line charts in a single component tree.
- Actively maintained; good TypeScript types.

**Alternatives considered**  
- D3.js: too low-level; requires manual React integration.
- Chart.js: Canvas-based, weaker React integration, harder to customise tooltips.
- Victory: similar to Recharts but smaller community.

**Consequences**  
- Large datasets (>10 k points) may need downsampling before passing to Recharts (browser SVG limit).

---

## ADR-006 · Prometheus + cAdvisor + node-exporter for live telemetry

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Need live microservice metrics (CPU, memory, network, latency) from a running containerised demo app.

**Decision**  
Run Prometheus with cAdvisor (container metrics) and node-exporter (host metrics) via Docker Compose. Demo app: Google Online Boutique.

**Rationale**  
- Prometheus is the de facto standard for Kubernetes/container metrics.
- cAdvisor exports per-container resource usage compatible with RE2-OB metric names.
- node-exporter covers host-level signals (disk I/O, network packets) matching RE2 fault types.

**Consequences**  
- Requires Docker Desktop running locally.
- Prometheus HTTP API used for metric queries (no Prometheus client library in Python backend — pull-based querying via REST).

---

## ADR-007 · Server-Sent Events (SSE) for live dashboard updates

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Dashboard needs near-real-time anomaly and alert updates without full WebSocket complexity.

**Decision**  
Implement SSE via FastAPI's `StreamingResponse` with `text/event-stream`. Fall back to 5-second polling if SSE is unavailable.

**Rationale**  
- SSE is unidirectional (server → client) — sufficient for push-only alert feeds.
- Native browser `EventSource` API; no extra libraries.
- Simpler than WebSockets: no handshake protocol, auto-reconnect built into browsers.

**Consequences**  
- SSE requires HTTP/1.1 keep-alive; reverse proxies (nginx) must pass `X-Accel-Buffering: no`.
- Maximum ~6 concurrent SSE connections per domain in HTTP/1.1 browsers (non-issue in dev).

---

## ADR-008 · RCAEval RE2 dataset — Online Boutique first, no cross-system generalisation

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
RE2 contains 270 fault-injection cases across three systems: Online Boutique (RE2-OB), Sock Shop (RE2-SS), Train Ticket (RE2-TT). Metric naming conventions differ per system.

**Decision**  
Develop and tune detection models exclusively on RE2-OB first. Validate on RE2-SS and RE2-TT only after RE2-OB results are satisfactory. Never assume a model trained on one system generalises to another without re-evaluation.

**Rationale**  
- Metric schemas differ: e.g., `container_cpu_usage_seconds_total` labels vary per deployment.
- Cross-system evaluation is a research question, not an assumption.
- Prevents silent model degradation on unseen systems.

**Consequences**  
- Preprocessing pipelines are system-specific; use a `system` config parameter.
- Phase 2 deliverables include separate evaluation reports for each system.

---

## ADR-009 · Train/eval split by fault case to prevent data leakage

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
RE2 time-series data has strong temporal autocorrelation within a fault case. Row-level random splitting would leak future data into training.

**Decision**  
Split by fault case ID (the outer experiment identifier). All time-series rows from a given case go entirely into train or eval — never split across the boundary. Scalers and imputers are fit only on the training cases.

**Rationale**  
- Prevents leakage: a detector that "knows" it will see the same fault type it was trained on is not generalisable.
- Matches real-world deployment where the system has never seen a specific fault instance before.

**Consequences**  
- Train/eval split ratio is approximate (depends on fault case sizes); document exact case counts in each split.
- Cross-validation must use `GroupKFold` with case IDs as groups.

---

## ADR-010 · Docker Compose for local monitoring stack; cloud deployment deferred to Phase 6

**Date:** 2026-10-25  
**Status:** Accepted

**Context**  
Full cloud deployment (GKE, EKS, or similar) is expensive and complex. Local dev must be reproducible without cloud credentials.

**Decision**  
All monitoring infrastructure (Prometheus, exporters, Online Boutique demo) runs via Docker Compose locally. Cloud deployment design is deferred to Phase 6.

**Rationale**  
- Keeps Phase 0–5 accessible without cloud accounts.
- Docker Compose is sufficient for demonstrating the full data pipeline end-to-end.
- Phase 6 will containerise the backend + frontend and produce Kubernetes manifests or a cloud-run config.

**Consequences**  
- `docker-compose.yml` in `monitoring/` is the single source of truth for the monitoring stack.
- Production `Dockerfile`s live in `deployment/docker/` (Phase 6).
