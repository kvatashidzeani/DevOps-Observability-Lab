# 🚀 DevOps Task Manager — CI/CD Pipeline Assignment

> **Assignment:** CI/CD Pipeline Automation & Deployment Strategies  
> **Stack:** Node.js · Express · Jest · GitHub Actions · Render

---

## 🌐 Live Application

**[https://devops-task-manager.onrender.com](https://devops-task-manager.onrender.com)**

> The app is a lightweight Task Manager with a REST API, deployed automatically to **Render** on every successful push to `main`.

---

## 📸 Screenshots

### Hosted Application
![App Screenshot](docs/screenshot-app.png)
*The live Task Manager running on Render's free tier*

### GitHub Actions – Successful Pipeline Run
![CI Pipeline Screenshot](docs/screenshot-ci.png)
*Both the `test` and `deploy` jobs completed successfully after a push to `main`*

### GitHub Actions – Failed Pipeline (Tests Block Deploy)
![Failed CI Screenshot](docs/screenshot-ci-fail.png)
*When tests fail, the `deploy` job is skipped entirely — broken code never reaches production*

---

## 🔄 Pipeline Description

The CI/CD flow is defined in **`.github/workflows/main.yml`** and consists of two sequential jobs:

```
git push to main
       │
       ▼
┌──────────────────────────────────┐
│  JOB 1: test  (Quality Gate)     │
│  ─────────────────────────────   │
│  • Checkout code                 │
│  • Set up Node.js (18.x & 20.x)  │
│  • npm ci  (install deps)        │
│  • npm run test:ci  (Jest)       │
│  • Upload coverage artifact      │
└──────────────┬───────────────────┘
               │  only if tests PASS
               ▼
┌──────────────────────────────────┐
│  JOB 2: deploy  (CD)             │
│  ─────────────────────────────   │
│  • Trigger Render Deploy Hook    │
│  • Wait 30s for stabilization    │
│  • Health-check /health endpoint │
│  • Tag release in Git            │
└──────────────────────────────────┘
```

### Triggers
| Event | Branch | What happens |
|-------|--------|-------------|
| `push` | `main` | CI + CD (full pipeline) |
| `push` | `develop` | CI only (tests run, no deploy) |
| `pull_request` | `main` | CI only (quality gate) |

### The Quality Gate Rule
The `deploy` job declares `needs: test`. GitHub Actions will **not start** the deploy job if the test job fails. A broken commit physically cannot reach production.

### Secrets Required
Set these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `RENDER_DEPLOY_HOOK_URL` | Render deploy hook URL (from your service dashboard) |
| `APP_URL` | Your live app URL (e.g. `https://devops-task-manager.onrender.com`) |

---

## ♻️ Deployment Strategy — Rolling Update

### Why Rolling Update?

I chose the **Rolling Update** strategy because it fits Render's free tier naturally:

- Render performs a rolling replacement: it starts a new instance of the container, waits for it to pass the health check, then terminates the old one.
- There is **zero downtime** — at least one healthy instance is always serving traffic.
- No extra infrastructure (no second environment, no load balancer configuration) is required, making it ideal for free-tier constraints.

### How It Works (Step by Step)

```
BEFORE DEPLOY:
  [Instance v1.0] ← serving 100% of traffic

DEPLOY TRIGGERED:
  [Instance v1.0] ← still serving traffic
  [Instance v1.1] ← starting up, running health check

HEALTH CHECK PASSES:
  [Instance v1.0] ← terminating
  [Instance v1.1] ← serving 100% of traffic

COMPLETE:
  [Instance v1.1] ← serving 100% of traffic
```

### How It Is Enforced in the Pipeline

1. The pipeline triggers the deploy hook only after all tests pass (`needs: test`).
2. After triggering, the workflow waits **30 seconds** for the new instance to spin up.
3. It then runs a **post-deploy health check** against `GET /health`.
4. If the health check fails (non-200), the pipeline step exits with code 1 and GitHub marks the run as failed — providing an immediate alert.

---

## 🔙 Rollback Guide

If a bug is discovered in production after a deployment, follow these steps:

### Option A — Rollback via Render Dashboard (Fastest)

1. Go to [https://dashboard.render.com](https://dashboard.render.com) and open your service.
2. Click the **"Deploys"** tab in the left sidebar.
3. Find the last **successful** deploy (green checkmark).
4. Click the three-dot menu (⋮) next to it and select **"Rollback to this deploy"**.
5. Render will spin up the previous image using the Rolling Update process.
6. Monitor the **Events** tab until the status shows `Live`.
7. Verify by hitting `GET /health` — confirm the `version` field matches the previous release.

### Option B — Rollback via Git Tag + Pipeline (Auditable)

Every successful deploy is tagged automatically (e.g., `release-20240615-143022`).

```bash
# 1. List available release tags
git tag --list "release-*" | sort | tail -10

# 2. Check out the last known-good tag
git checkout release-20240615-143022

# 3. Create a new branch from this tag
git checkout -b hotfix/rollback-to-20240615

# 4. Push to main to trigger the pipeline
git push origin hotfix/rollback-to-20240615
# Open a PR → merge to main → pipeline redeploys the stable version

# 5. Verify health check
curl https://devops-task-manager.onrender.com/health
```

### Option C — Rollback via Render CLI

```bash
# Install Render CLI
npm install -g @render-oss/render-cli

# List recent deploys for your service
render deploys list --service-id <YOUR_SERVICE_ID> --output json

# Rollback to specific deploy ID
render deploys create --service-id <YOUR_SERVICE_ID> --image-url <PREVIOUS_IMAGE_URL>
```

### Post-Rollback Checklist

- [ ] Verify `GET /health` returns `status: ok`
- [ ] Confirm the `version` field matches the intended release
- [ ] Check Render logs for any startup errors
- [ ] Notify the team / open a GitHub Issue for the root-cause bug
- [ ] Add a regression test before re-deploying the fix

---

## 🗂️ Project Structure

```
.
├── .github/
│   └── workflows/
│       └── main.yml          # CI/CD pipeline definition
├── public/
│   └── index.html            # Frontend SPA
├── src/
│   ├── app.js                # Express app (routes)
│   └── server.js             # HTTP server entry point
├── tests/
│   └── app.test.js           # Jest test suite (8 tests)
├── render.yaml               # Render deployment config
├── package.json
└── README.md
```

---

## 🧪 Running Locally

```bash
# Clone the repo
git clone https://github.com/<your-username>/devops-assignment.git
cd devops-assignment

# Install dependencies
npm install

# Run tests
npm test

# Start development server
npm start
# → http://localhost:3000
```

### Test Coverage

```
 PASS  tests/app.test.js
  Health Check
    ✓ GET /health returns 200 and status ok
  Tasks API
    ✓ GET /api/tasks returns empty array
    ✓ POST /api/tasks creates a task with valid title
    ✓ POST /api/tasks returns 400 if title missing
    ✓ POST /api/tasks returns 400 if title is empty
  Math API
    ✓ GET /api/add adds two numbers
    ✓ GET /api/add handles floats
    ✓ GET /api/add returns 400 for invalid input

Tests: 8 passed  |  Coverage: 100% (app.js)
```

---

## ✅ Evaluation Criteria — Self Assessment

| Criterion | Status | Evidence |
|-----------|--------|---------|
| **Automation** | ✅ | Pipeline triggers on push, no manual steps |
| **Reliability** | ✅ | `needs: test` blocks deploy on any test failure |
| **Documentation** | ✅ | This README with screenshots, guides, diagrams |
| **Strategic Thinking** | ✅ | Rolling update explained and justified; 3-option rollback guide |

---

*Built for DevOps coursework · Node.js + Express + Jest + GitHub Actions + Render*
