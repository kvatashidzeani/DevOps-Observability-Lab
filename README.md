# DevOps Final Project

This monorepo combines three DevOps coursework projects into one repository: **Assignment 1** (CI/CD Task Manager), the **Midterm** (Flask app with blue-green deployment automation), and the **Observability Lab** (metrics, logs, and alerting with Docker Compose).

## Projects

- [assignment-1](assignment-1/) — Node.js Task Manager with GitHub Actions CI/CD and Render deployment
- [midterm](midterm/) — Python Flask app with pytest, Flake8 CI, and PowerShell blue-green deploy scripts
- [observability-lab](observability-lab/) — Containerized Flask app with Prometheus, Grafana, Loki, Promtail, and Alertmanager

## Quick start

### assignment-1

```powershell
cd assignment-1
npm install
npm test
npm start
```

App: http://localhost:3000

### midterm

```powershell
cd midterm
.\scripts\setup_env.ps1
.\scripts\run_local_prod.ps1
```

Or manually: create a virtualenv, `pip install -r requirements.txt`, then `python app.py`. Health: http://localhost:5000/health

### observability-lab

```powershell
cd observability-lab
docker compose up -d --build
```

App: http://localhost:8080. Grafana: http://localhost:3000 (admin / admin).

```powershell
docker compose down
```
