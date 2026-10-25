# System Architecture Overview

> This document is a living document. It will be updated as phases progress.

## Phase 0 — Skeleton

At project inception the system has the following high-level components:

```
Data Sources
  ├── RCAEval RE2 (offline CSV/Parquet files)
  │     270 fault-injection cases: RE2-OB · RE2-SS · RE2-TT
  └── Live Prometheus (Docker Compose stack)
        cAdvisor + node-exporter → Prometheus HTTP API

Backend  (Python 3.14 · FastAPI 0.162 · Uvicorn 0.54)
  ├── Preprocessing    (Pandas 3.0 · NumPy 2.3)
  ├── Anomaly Detection (scikit-learn 1.8)
  ├── Alert Aggregation
  ├── REST API  (/api/v1/*)
  ├── SSE Stream (/api/v1/events)
  └── Database  (SQLite dev → PostgreSQL prod via SQLAlchemy)

Frontend  (React 18 · Vite · TypeScript · Recharts)
  ├── Dashboard: multi-metric time-series with anomaly overlays
  ├── Alert feed (SSE or polling fallback)
  └── API client (VITE_API_BASE_URL env var)
```

## Data Flow (Phase 1+)

```
[RE2 CSV] ──▶ [Ingest] ──▶ [Preprocess] ──▶ [Detect] ──▶ [Alert] ──▶ [DB]
                                                                         │
[Prometheus] ──▶ [Scrape] ──▶ [Preprocess] ──▶ [Detect] ──▶ [Alert] ──▶┘
                                                                         │
                                                             [API] ◀─────┘
                                                               │
                                                         [SSE/Poll]
                                                               │
                                                        [Dashboard]
```

## Component Responsibilities

| Component | Responsibility | Phase |
|-----------|---------------|-------|
| `preprocessing/` | Normalise, impute, engineer features | 1 |
| `detection/` | Fit and serve anomaly models | 2 |
| `alerts/` | Deduplicate, enrich, score alerts | 3 |
| `api/routes.py` | Expose REST + SSE endpoints | 3 |
| `frontend/` | Visualise metrics + alert feed | 4 |
| `monitoring/` | Live telemetry collection | 5 |
| `deployment/` | Containerise + cloud deploy | 6 |
