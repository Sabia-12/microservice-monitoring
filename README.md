# Real-Time Microservice Monitoring, Anomaly Detection & Intelligent Alert Generation

[![Python](https://img.shields.io/badge/Python-3.14-blue)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.162-green)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-Vite-purple)](https://vitejs.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A student research project that ingests microservice telemetry (historical RCAEval RE2 fault-injection data and live Prometheus metrics), detects anomalies using scikit-learn models, aggregates and enriches alerts, exposes them via a FastAPI REST API, and visualises everything in a React + Vite dashboard with live Server-Sent Events updates.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Data Sources                              │
│  ┌──────────────────┐          ┌─────────────────────────────┐  │
│  │  RCAEval RE2     │          │  Live Prometheus metrics     │  │
│  │  (historical)    │          │  cAdvisor + node-exporter   │  │
│  └────────┬─────────┘          └──────────────┬──────────────┘  │
└───────────┼──────────────────────────────────┼──────────────────┘
            │                                  │
            ▼                                  ▼
┌───────────────────────────────────────────────────────────────────┐
│                     Backend (FastAPI / Python 3.14)               │
│                                                                   │
│  ┌─────────────────┐   ┌──────────────────┐  ┌────────────────┐  │
│  │  Preprocessing  │──▶│  Anomaly         │─▶│  Alert         │  │
│  │  (Pandas/NumPy) │   │  Detection       │  │  Aggregation   │  │
│  └─────────────────┘   │  (scikit-learn)  │  └───────┬────────┘  │
│                        └──────────────────┘          │           │
│                                                       ▼           │
│                        ┌──────────────────────────────────────┐  │
│                        │  REST API + SSE  (FastAPI/Uvicorn)   │  │
│                        └──────────────────┬───────────────────┘  │
│                                           │                       │
│                        ┌──────────────────▼───────────────────┐  │
│                        │  SQLite (dev) / PostgreSQL (prod)     │  │
│                        └──────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────────┐
│             Frontend (React + Vite + TypeScript)                   │
│  Recharts dashboards · Alert feed · SSE live updates              │
└───────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

| Tool | Minimum version | Install |
|------|----------------|---------|
| Python | 3.14 | [python.org](https://python.org) |
| Node.js | 20 LTS | [nodejs.org](https://nodejs.org) |
| npm | 10+ | bundled with Node |
| Docker Desktop | 24+ | [docker.com](https://docker.com) |
| Docker Compose | v2 | bundled with Docker Desktop |
| Git | 2.40+ | [git-scm.com](https://git-scm.com) |
| GitHub CLI (`gh`) | 2.x | [cli.github.com](https://cli.github.com) |

---

## Quick Start (Local Development)

### 1 — Clone the repository

```bash
git clone https://github.com/<YOUR_USERNAME>/microservice-monitoring.git
cd microservice-monitoring
```

### 2 — Backend

```bash
# Create and activate virtual environment
py -3.14 -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Windows Git Bash / macOS / Linux
source .venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt

# Copy example env file
cp .env.example .env        # then edit as needed

# Start the API server
uvicorn backend.app.main:app --reload --port 8000
```

API docs available at: http://localhost:8000/docs

### 3 — Dataset (RCAEval RE2)

> ⚠️ **Large files are NOT committed to this repo.** Download them separately using the provided scripts.

**PowerShell (Windows):**
```powershell
.\data-analysis\download_dataset.ps1
```

**Bash (Git Bash / WSL / macOS / Linux):**
```bash
bash data-analysis/download_dataset.sh
```

See [`data-analysis/download_dataset.ps1`](data-analysis/download_dataset.ps1) for manual download links and SHA-256 checksums.

### 4 — Frontend

```bash
cd frontend
npm install
npm run dev
```

Dashboard available at: http://localhost:5173

### 5 — Monitoring Stack (Prometheus + exporters)

```bash
docker compose -f monitoring/docker-compose.yml up -d
```

Prometheus UI: http://localhost:9090

---

## Environment Variables

Copy `.env.example` to `.env` and set values:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `sqlite:///./dev.db` | SQLAlchemy connection string |
| `API_HOST` | `0.0.0.0` | Uvicorn bind host |
| `API_PORT` | `8000` | Uvicorn bind port |
| `PROMETHEUS_URL` | `http://localhost:9090` | Prometheus base URL |
| `LOG_LEVEL` | `INFO` | Python log level |
| `CORS_ORIGINS` | `http://localhost:5173` | Comma-separated allowed origins |
| `VITE_API_BASE_URL` | `http://localhost:8000` | Frontend → API base URL |

---

## Running Tests

```bash
# From the repo root with venv active
pytest backend/tests/ -v
```

---

## Project Structure

```
microservice-monitoring/
├── backend/
│   ├── app/           # FastAPI application factory + config
│   ├── api/           # Route handlers
│   ├── detection/     # Anomaly detection models
│   ├── preprocessing/ # Data ingestion and feature engineering
│   ├── alerts/        # Alert aggregation and enrichment
│   ├── tests/         # Unit + integration tests
│   └── requirements.txt
├── frontend/          # React + Vite + TypeScript dashboard
├── data-analysis/
│   ├── notebooks/     # Exploratory analysis
│   ├── evaluation/    # Model evaluation results
│   └── download_dataset.{sh,ps1}
├── monitoring/
│   ├── prometheus/    # prometheus.yml scrape config
│   ├── exporters/     # cAdvisor + node-exporter configs
│   └── docker-compose.yml
├── deployment/
│   ├── docker/        # Production Dockerfiles
│   └── cloud/         # Cloud deployment configs (Phase 6+)
├── docs/
│   ├── decisions.md   # Architecture Decision Records
│   ├── architecture/  # System diagrams
│   └── reports/       # Phase summary reports
└── README.md
```

---

## Dataset Notice

This project uses the **RCAEval RE2** dataset (270 fault-injection cases across Online Boutique, Sock Shop, and Train Ticket microservice benchmarks). The dataset is **not included in this repository** due to size constraints. Download instructions are in [`data-analysis/download_dataset.ps1`](data-analysis/download_dataset.ps1).

Please respect the dataset's original license terms when using it.

---

## Development Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repo skeleton + tooling | ✅ Done |
| 1 | Data ingestion + EDA | 🔜 Next |
| 2 | Baseline anomaly detection | ⏳ |
| 3 | FastAPI REST API | ⏳ |
| 4 | React dashboard + SSE | ⏳ |
| 5 | Live Prometheus integration | ⏳ |
| 6 | Cloud deployment | ⏳ |

---

## Contributing

This is a student project. See [`docs/decisions.md`](docs/decisions.md) for architectural decisions.

---

## License

MIT — see [LICENSE](LICENSE).
