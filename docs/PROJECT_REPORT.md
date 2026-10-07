# SecureNotes — Detailed Project Report
### DevSecOps Secure CI/CD Pipeline with AI-Powered Remediation

> **Authors:** Siddhant Shukla & Siddhant Raut  
> **Project:** SecureNotes DevOps Miniproject  
> **Date:** October 2026  
> **Repository:** [SecureNotes_Devops_Miniproject](https://github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Overview & Objectives](#2-project-overview--objectives)
3. [Technology Stack](#3-technology-stack)
4. [System Architecture](#4-system-architecture)
5. [Application Design](#5-application-design)
6. [DevSecOps CI/CD Pipeline](#6-devsecops-cicd-pipeline)
7. [Security Gates & Shift-Left Model](#7-security-gates--shift-left-model)
8. [AI Remediation Agent (NVIDIA Nemotron)](#8-ai-remediation-agent-nvidia-nemotron)
9. [Testing Strategy](#9-testing-strategy)
10. [Containerization & Docker](#10-containerization--docker)
11. [Demo Profiles & Reset Tooling](#11-demo-profiles--reset-tooling)
12. [Environment Configuration](#12-environment-configuration)
13. [Data Flow & Request Lifecycle](#13-data-flow--request-lifecycle)
14. [Security Analysis & Findings](#14-security-analysis--findings)
15. [Conclusion & Key Learnings](#15-conclusion--key-learnings)

---

## 1. Executive Summary

**SecureNotes** is a fully containerized Flask web application built as a practical demonstration of **DevSecOps** principles — specifically the **Shift-Left Security** methodology and **Human-in-the-Loop AI Remediation**. The project integrates automated security scanning, container hardening, and an NVIDIA NIM-powered AI agent that autonomously diagnoses and patches security vulnerabilities, all governed by a strict multi-stage GitHub Actions CI/CD pipeline.

> [!IMPORTANT]
> The pipeline enforces a **zero-trust gate model** — no container artifact reaches the public registry unless it passes both static code analysis (SonarCloud) AND container vulnerability scanning (Trivy).

### Key Achievements at a Glance

| Dimension | Outcome |
|---|---|
| Static Code Gate | SonarCloud Quality Gate enforced on every push |
| Container CVE Gate | Trivy blocks on HIGH or CRITICAL CVEs |
| AI Remediation | NVIDIA Nemotron generates targeted security patches |
| Human Oversight | All AI fixes require developer PR review before merge |
| Test Coverage | 6 automated pytest cases covering all API routes |
| Demo Profiles | 4 pre-configured states for repeatable demonstrations |

---

## 2. Project Overview & Objectives

### 2.1 Problem Statement

Modern software delivery pipelines often treat security as an afterthought — vulnerabilities are discovered in production, remediation is manual and slow, and developers lack real-time feedback on security issues they introduce. This project addresses these gaps by:

1. **Shifting security left** — detecting issues at code-commit time, not deployment time.
2. **Automating remediation** — an AI agent proposes fixes, eliminating manual triage delays.
3. **Enforcing human oversight** — the AI agent cannot merge its own changes; a human developer reviews every proposed fix.

### 2.2 Core Application Features

- **Note Management**: Create, view, and delete notes via a server-rendered web UI.
- **Input Sanitization**: Server-side validation rejects empty, whitespace-only, or malformed payloads.
- **Ephemeral In-Memory Store**: Thread-safe in-place slice mutation for the container lifetime.
- **Health Endpoint**: JSON-formatted `/health` endpoint for container readiness probes.
- **Responsive UI**: Built with Google Fonts (Inter), crisp inline SVG icons, no external CSS frameworks.
- **1-Click Windows Launcher**: `run.bat` auto-resolves Python, activates venv, installs deps, opens browser.

### 2.3 DevOps Objectives

```mermaid
mindmap
  root((SecureNotes Goals))
    Security
      Shift-Left Detection
      Static Code Analysis
      Container CVE Scanning
      Secret Detection
    Automation
      CI/CD Pipeline
      Automated Testing
      AI Remediation Agent
      Auto PR Creation
    Compliance
      Quality Gates
      Human Review Enforcement
      Audit Trail via PRs
    Repeatability
      4 Demo Profiles
      Reset Tooling Scripts
      Mock Mode Testing
```

---

## 3. Technology Stack

### 3.1 Component Overview

```mermaid
graph TB
    subgraph Application["Application Layer"]
        Flask["Flask 3.0.3\nWeb Framework"]
        Gunicorn["Gunicorn 22.0.0\nWSGI Server"]
        Python["Python 3.12\nRuntime"]
    end

    subgraph Container["Container Layer"]
        Docker["Docker\nContainerization"]
        BaseImage["python:3.12-slim\nHardened Base Image"]
    end

    subgraph CICD["CI/CD Layer"]
        GHA["GitHub Actions\nPipeline Orchestrator"]
        Pytest["Pytest + Coverage\nTest Runner"]
    end

    subgraph Security["Security Layer"]
        Sonar["SonarCloud\nStatic Analysis + SAST"]
        Trivy["Trivy\nContainer CVE Scanner"]
    end

    subgraph AI["AI Layer"]
        NIM["NVIDIA NIM API\nNemotron 70B"]
        Agent["remediate_agent.py\nOrchestration Script"]
    end

    subgraph Registry["Registry"]
        DockerHub["Docker Hub\nContainer Registry"]
    end

    Flask --> Gunicorn
    Python --> Flask
    Docker --> BaseImage
    Gunicorn --> Docker
    GHA --> Pytest
    GHA --> Sonar
    GHA --> Trivy
    GHA --> Agent
    Agent --> NIM
    GHA --> DockerHub
```

### 3.2 Dependency Matrix

| Package | Version | Purpose |
|---|---|---|
| `Flask` | 3.0.3 | Web framework, routing, template rendering |
| `Gunicorn` | 22.0.0 | Production-grade WSGI HTTP server |
| `pytest` | 8.2.2 | Automated test runner |
| `requests` | 2.32.3 | HTTP client (used by remediation agent) |
| `python-dotenv` | 1.0.1 | `.env` file environment loading |
| `coverage` | 7.5.4 | Code coverage measurement |
| `pytest-cov` | 5.0.0 | Coverage plugin for pytest |

---

## 4. System Architecture

### 4.1 High-Level CI/CD Pipeline Architecture

```mermaid
graph TD
    Dev["Developer\ngit push or PR"] --> GH["GitHub Repository\nmain branch"]
    GH --> GA["GitHub Actions\nCI/CD Pipeline Trigger"]

    subgraph Stage1 ["Stage 1: Code Security Gate"]
        GA --> J1["Job: code-quality"]
        J1 --> Tests["Run Pytest Suite\nwith Coverage Report"]
        Tests --> SC["SonarCloud Scan\nSAST + Secret Detection"]
        SC --> QG{"Quality Gate\nPassed?"}
    end

    subgraph Stage2 ["Stage 2: Container Security Gate"]
        QG -->|"Passed"| J2["Job: build-and-scan"]
        J2 --> Build["docker build\nsample-app:latest"]
        Build --> TrivyJSON["Trivy Scan to JSON\nArtifact Upload"]
        TrivyJSON --> TrivyGate["Trivy Gate\nexit-code 1 on HIGH/CRITICAL"]
        TrivyGate --> CVECheck{"Zero HIGH or\nCRITICAL CVEs?"}
    end

    subgraph Stage3 ["Stage 3: Registry Delivery"]
        CVECheck -->|"Clean"| J3["Job: publish"]
        J3 --> Login["Docker Hub Auth\ndocker/login-action"]
        Login --> Push["Build and Push\ndocker/build-push-action"]
        Push --> Registry[("Docker Hub\nRegistry")]
    end

    subgraph Stage4 ["Stage 4: Agentic Remediation"]
        QG -->|"Gate Failed"| RA["Job: remediate"]
        CVECheck -->|"CVEs Found"| RA
        RA --> NIM["NVIDIA NIM API\nllama-3.1-nemotron-70b-instruct"]
        NIM --> Patch["Generate Scoped Patch\nand Plain-Language Explanation"]
        Patch --> PR["Open Pull Request\nagent-fix/security-remediation"]
        PR --> Review["Developer Review\nand Approval Gate"]
        Review -->|"Merge PR"| GH
    end
```

### 4.2 Repository & File Structure

```
SecureNotes_Devops_Miniproject/
├── app.py                          # Flask application core
├── Dockerfile                      # Hardened container image definition
├── requirements.txt                # Python dependencies
├── sonar-project.properties        # SonarCloud scan configuration
├── pytest.ini                      # Pytest configuration
├── .env / .env.example             # Environment variable templates
├── run.bat                         # Windows 1-click launcher
├── reset-demo.bat                  # Demo state reset (Windows)
│
├── .github/
│   └── workflows/
│       └── pipeline.yml            # 4-Stage GitHub Actions pipeline
│
├── scripts/
│   ├── remediate_agent.py          # NVIDIA NIM remediation agent
│   ├── reset-demo.ps1              # PowerShell reset script
│   └── reset-demo.sh               # Bash reset script (Linux/macOS)
│
├── tests/
│   └── test_app.py                 # 6 pytest unit test cases
│
├── templates/
│   └── index.html                  # Server-rendered Jinja2 template
│
├── static/                         # CSS and static assets
│
├── demo-states/
│   ├── vulnerable/                 # Seeded: python:3.8 + hardcoded secret
│   ├── fixed/                      # Clean: python:3.12-slim + env var auth
│   ├── agent-secret-only/          # Isolated: secret only, clean base
│   └── agent-image-only/           # Isolated: vulnerable base, clean app
│
└── docs/
    └── PROJECT_REPORT.md           # This document
```

---

## 5. Application Design

### 5.1 API Endpoint Map

```mermaid
graph LR
    Browser["Browser or Client"] --> GET_ROOT["GET /\nRender Notes UI"]
    Browser --> POST_ADD["POST /add\nCreate Note"]
    Browser --> POST_DEL["POST /delete/id\nDelete Note"]
    Browser --> GET_HEALTH["GET /health\nReadiness Check"]

    GET_ROOT --> Template["index.html\nJinja2 Template"]
    POST_ADD --> Validate{"validate_note_input\nnon-empty check"}
    Validate -->|"Valid"| Store["notes_db.insert(0, note)"]
    Validate -->|"Invalid"| Redirect["302 Redirect to /"]
    Store --> Redirect
    POST_DEL --> ValidID{"validate_note_input\nid check"}
    ValidID -->|"Valid"| Filter["notes_db filtered list"]
    ValidID -->|"Invalid"| Redirect
    Filter --> Redirect
    GET_HEALTH --> JSON["status: ok\nservice: securenotes\ntimestamp: ISO"]
```

### 5.2 In-Memory Data Model

```mermaid
erDiagram
    NOTE {
        string id PK "UUID prefix first 8 chars of uuid4"
        string text "Note content string non-empty stripped"
        string created_at "Formatted timestamp YYYY-MM-DD HH-MM-SS"
    }

    NOTES_DB {
        list store "Ephemeral Python list container-lifetime only"
    }

    NOTES_DB ||--o{ NOTE : "contains ordered newest-first"
```

> [!NOTE]
> The in-memory store (`notes_db`) is an ephemeral Python list. All notes are lost when the container restarts. This is an intentional design choice for a demo application — a production system would use a persistent database.

### 5.3 Note Lifecycle Flowchart

```mermaid
flowchart TD
    A["User opens localhost:5000"] --> B["GET / — Render full notes list"]
    B --> C{"User action?"}

    C -->|"Type note and submit"| D["POST /add\nnote=text"]
    D --> E{"validate_note_input\ntext non-empty?"}
    E -->|"No — empty or whitespace"| F["Redirect to / (no-op)"]
    E -->|"Yes"| G["Generate UUID 8 chars + timestamp"]
    G --> H["notes_db.insert(0, new_note)\nprepend to list"]
    H --> I["302 Redirect to /"]
    I --> B

    C -->|"Click Delete button"| J["POST /delete/id"]
    J --> K{"validate_note_input\nid non-empty?"}
    K -->|"No"| F
    K -->|"Yes"| L["Filter: keep notes where id != note_id"]
    L --> I
    F --> B
```

---

## 6. DevSecOps CI/CD Pipeline

### 6.1 Pipeline Trigger Conditions

```mermaid
flowchart LR
    Push["git push to main"] --> Trigger
    PullReq["Pull Request to main"] --> Trigger
    Manual["workflow_dispatch\nforce_remediate flag"] --> Trigger
    Trigger["pipeline.yml\nGitHub Actions"] --> Jobs["4-Stage Job Graph"]
```

### 6.2 Detailed Job Dependency Graph

```mermaid
graph LR
    subgraph Jobs
        CQ["code-quality\nStage 1"]
        BAS["build-and-scan\nStage 2\nneeds: code-quality"]
        PUB["publish\nStage 3\nneeds: build-and-scan"]
        REM["remediate\nStage 4\nif: failure()"]
    end

    CQ -->|"pass"| BAS
    BAS -->|"pass"| PUB
    CQ -->|"fail"| REM
    BAS -->|"fail"| REM
```

### 6.3 Stage 1 — Code Quality & Secret Scan (SonarCloud)

**Job:** `code-quality` | **Runner:** `ubuntu-latest`

```mermaid
flowchart TD
    S1["actions/checkout@v4\nfetch-depth: 0 full history"] --> S2
    S2["actions/setup-python@v5\nPython 3.12 + pip cache"] --> S3
    S3["pip install -r requirements.txt"] --> S4
    S4["coverage run -m pytest tests\ncoverage xml -o coverage.xml"] --> S5
    S5["sonarsource/sonarqube-scan-action@v4\nSAST + secret detection + code smells"] --> S6
    S6["sonarqube-quality-gate-action@v1.1.0\ntimeout: 5 minutes"] --> S7{"Quality Gate?"}
    S7 -->|"Passed"| NEXT["Stage 2: build-and-scan"]
    S7 -->|"Failed"| FAIL["Stage 4: remediate"]
```

**SonarCloud Rules Enforced:**
- `python:S2068` — Hardcoded credential / secret detection
- Code smell analysis (duplication, complexity)
- Quality Gate blocks pipeline on unresolved hotspots

### 6.4 Stage 2 — Container Build & CVE Scan (Trivy)

**Job:** `build-and-scan` | **Runner:** `ubuntu-latest` | **Needs:** `code-quality`

```mermaid
flowchart TD
    T1["actions/checkout@v4"] --> T2
    T2["docker/setup-buildx-action@v3"] --> T3
    T3["docker build -t sample-app:latest ."] --> T4
    T4["aquasecurity/trivy-action@master\nformat: JSON\noutput: trivy-results.json\nseverity: CRITICAL,HIGH\nignore-unfixed: true"] --> T5
    T5["actions/upload-artifact@v4\nname: trivy-scan-results\nretention: 7 days"] --> T6
    T6["aquasecurity/trivy-action@master\nformat: table\nexit-code: 1\nvuln-type: os,library\nseverity: CRITICAL,HIGH"] --> T7{"CVEs Found?"}
    T7 -->|"None"| PASS["Stage 3: publish"]
    T7 -->|"Found"| FAIL["Stage 4: remediate"]
```

> [!TIP]
> Trivy runs **twice**: once to produce a JSON artifact for the AI remediation agent, and once again with `exit-code: 1` to enforce the pipeline gate. The JSON artifact is uploaded even on failure so the remediation agent can parse it.

### 6.5 Stage 3 — Registry Delivery (Docker Hub)

**Job:** `publish` | **Runner:** `ubuntu-latest` | **Needs:** `build-and-scan`

```mermaid
flowchart TD
    P1["actions/checkout@v4"] --> P2
    P2["docker/login-action@v3\nDOCKERHUB_USERNAME + DOCKERHUB_TOKEN"] --> P3
    P3["docker/build-push-action@v5\ncontext: .\npush: true\ntags: username/securenotes:latest"] --> P4["Image Live on Docker Hub"]
```

---

## 7. Security Gates & Shift-Left Model

### 7.1 Shift-Left Security Principle

"Shift Left" means moving security checks as early as possible in the development lifecycle — before code reaches production, or even before it is built into a container.

```mermaid
flowchart LR
    A["1. Code Creation\nDeveloper writes code"] -->|"git push"| B
    B["2. Static and Secret Gate\nSonarCloud Analysis"] -->|"Failure"| Rem1["AI Remediation PR"]
    B -->|"Pass"| C
    C["3. Container Build\ndocker build"] --> D
    D["4. CVE Image Gate\nTrivy Scan"] -->|"Failure"| Rem2["AI Remediation PR"]
    D -->|"Pass"| E["5. Trusted Registry\nDocker Hub"]
```

### 7.2 Security Layer Summary

| Layer | Tool | What It Detects | Action on Failure |
|---|---|---|---|
| **Code / SAST** | SonarCloud | Hardcoded secrets (`python:S2068`), code smells, duplication | Blocks pipeline, triggers AI remediation |
| **Container OS** | Trivy | CVEs in base OS packages (Debian), library vulnerabilities | Blocks pipeline, triggers AI remediation |
| **AI Boundary** | Human Review | PR review before any merge | Developer must approve; agent cannot self-merge |

### 7.3 Vulnerability Seeding vs. Hardened States

```mermaid
graph TB
    subgraph Vulnerable["Vulnerable State"]
        V1["Dockerfile: FROM python:3.8\nknown HIGH/CRITICAL CVEs"]
        V2["app.py: API_KEY = 'hardcoded-secret-value'\nSonarCloud S2068 trigger"]
        V3["Duplicate validation logic\ncode smell"]
    end

    subgraph Fixed["Hardened State"]
        F1["Dockerfile: FROM python:3.12-slim\nminimal patched base"]
        F2["app.py: API_KEY = os.environ.get('APP_SECRET_KEY')\nenv var loading"]
        F3["Unified validate_note_input helper\nDRY no duplication"]
    end

    subgraph APTUpdate["Additional Hardening"]
        A1["apt-get update and apt-get upgrade -y\nClears Debian-level CVEs at build time"]
    end

    Vulnerable -->|"AI Remediation\nNemotron Patch"| Fixed
    Fixed --> APTUpdate
```

---

## 8. AI Remediation Agent (NVIDIA Nemotron)

### 8.1 Agent Architecture

```mermaid
flowchart TD
    Trigger["Pipeline Gate Fails\nCode or Container"] --> Launch["Job: remediate\nlaunches on failure()"]
    Launch --> Download["actions/download-artifact@v4\nDownload trivy-results.json if available"]
    Download --> Script["python scripts/remediate_agent.py\n--finding-type both"]

    subgraph AgentLogic["remediate_agent.py Internal Logic"]
        Script --> Extract["Extract Finding:\nCode: SonarCloud API issue list\nImage: Parse trivy-results.json"]
        Extract --> Prompt["Construct Scoped Prompt:\nInclude current file content\nSpecify exact finding location\nRequest unified diff output"]
        Prompt --> NIM_Call["POST /v1/chat/completions\nnvidia/llama-3.1-nemotron-70b-instruct"]
        NIM_Call --> Parse["Parse JSON Response:\ndiff: unified patch\ntitle: PR title\nexplanation: human-readable summary"]
        Parse --> Apply["Apply Patch to Files:\napp.py or Dockerfile\nWrite pr_title.txt\nWrite pr_body.md"]
    end

    Apply --> Branch["git checkout -b\nagent-fix/security-remediation"]
    Branch --> CreatePR["peter-evans/create-pull-request@v6\nLabels: security automated-fix needs-review\nBody: pr_body.md\nToken: GITHUB_TOKEN"]
    CreatePR --> DevReview["Developer Reviews\nDiff and Explanation on GitHub PR"]
    DevReview --> Decision{"Approve?"}
    Decision -->|"Merge"| NewRun["Fresh CI/CD Run on main\nShould pass all gates"]
    Decision -->|"Close"| Manual["Manual fix or\nPR revision"]
```

### 8.2 Agent Operation Modes

| Mode | Command | Description |
|---|---|---|
| **Mock - Code** | `python scripts/remediate_agent.py --finding-type code --mock` | Simulates SonarCloud finding; patches hardcoded secret + extracts helper |
| **Mock - Image** | `python scripts/remediate_agent.py --finding-type image --mock` | Simulates Trivy finding; upgrades base image to `python:3.12-slim` |
| **Live - Both** | `python scripts/remediate_agent.py --finding-type both` | Live mode: queries SonarCloud API + parses Trivy JSON + calls NVIDIA NIM |

### 8.3 Human-in-the-Loop Boundary

```mermaid
graph LR
    AI["NVIDIA Nemotron\nAI Agent"] -->|"Can only do"| Actions["Open Pull Request\nWrite diff to branch\nAdd labels\nWrite PR description"]
    AI -->|"Cannot do"| Blocked["Merge PR\nPush directly to main\nApprove own PR\nBypass review"]
    Human["Developer"] -->|"Must perform"| Required["Review diff\nApprove or reject\nMerge if satisfied"]
```

> [!CAUTION]
> Workflow permissions are **explicitly scoped**: `contents: write` and `pull-requests: write` only. Direct push to `main` is blocked; the agent's only mechanism to affect production is through the PR review gate.

---

## 9. Testing Strategy

### 9.1 Test Suite Overview

The project includes **6 automated pytest test cases** in `tests/test_app.py` covering all API routes and edge cases.

```mermaid
flowchart LR
    Runner["pytest runner\ncoverage run -m pytest tests/"] --> F1 & F2

    F1["Fixture: client\nFlask test client\nTESTING=True"] --> Tests
    F2["Fixture: reset_notes\nautouse=True\nResets notes_db before each test"] --> Tests

    subgraph Tests["Test Cases"]
        T1["test_health_check\nGET /health returns 200\nJSON has status service timestamp"]
        T2["test_index_page\nGET / returns 200\nHTML contains SecureNotes and note text"]
        T3["test_add_note_success\nPOST /add returns 200\nNote appears in list count plus 1"]
        T4["test_add_note_empty_rejected\nPOST /add whitespace returns 200\nStore unchanged"]
        T5["test_delete_note_success\nPOST /delete/test-1 returns 200\nStore empty No active notes shown"]
        T6["test_delete_note_nonexistent\nPOST /delete/bad-id returns 200\nGraceful no-op count unchanged"]
    end
```

### 9.2 Test Coverage Matrix

| Test Case | Route | Method | Expected Status | Assertion |
|---|---|---|---|---|
| `test_health_check` | `/health` | GET | 200 | JSON keys: `status`, `service`, `timestamp` |
| `test_index_page` | `/` | GET | 200 | HTML contains `SecureNotes` and existing note text |
| `test_add_note_success` | `/add` | POST | 200 (after redirect) | Note visible in DOM; `notes_db` count = 2 |
| `test_add_note_empty_rejected` | `/add` | POST | 200 (after redirect) | `notes_db` count unchanged |
| `test_delete_note_success` | `/delete/test-1` | POST | 200 (after redirect) | `notes_db` count = 0; "No active notes" visible |
| `test_delete_note_nonexistent` | `/delete/bad-id` | POST | 200 (after redirect) | `notes_db` count unchanged |

### 9.3 Coverage Configuration

Coverage is collected via:
```bash
python -m coverage run -m pytest tests/
python -m coverage xml -o coverage.xml   # consumed by SonarCloud
```

The `coverage.xml` artifact is consumed by SonarCloud for combined code quality and coverage reporting.

---

## 10. Containerization & Docker

### 10.1 Dockerfile Layers

```mermaid
graph TD
    L1["FROM python:3.12-slim\nHardened minimal Debian base\nNemotron-proposed remediation"]
    L2["WORKDIR /app\nSet working directory"]
    L3["RUN apt-get update and apt-get upgrade -y\nApply latest Debian security patches"]
    L4["COPY requirements.txt\nRUN pip install --no-cache-dir\nInstall Python dependencies"]
    L5["COPY . .\nCopy application source"]
    L6["EXPOSE 5000\nDocument port"]
    L7["CMD gunicorn --bind 0.0.0.0:5000 app:app\nProduction WSGI server"]

    L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7
```

### 10.2 Base Image Evolution

| State | Base Image | Risk | Trivy Gate |
|---|---|---|---|
| **Vulnerable** | `python:3.8` | HIGH/CRITICAL Debian CVEs | Blocks |
| **Hardened** | `python:3.12-slim` + `apt-get upgrade` | Minimal exposure | Passes |

### 10.3 Local Container Commands

```bash
# Build
docker build -t securenotes:local .

# Run
docker run -d -p 5000:5000 --name securenotes-container securenotes:local

# Verify health
curl http://localhost:5000/health

# Stop and clean up
docker stop securenotes-container && docker rm securenotes-container
```

---

## 11. Demo Profiles & Reset Tooling

### 11.1 Demo State Machine

```mermaid
stateDiagram-v2
    [*] --> Vulnerable : Initial demo setup

    Vulnerable : Vulnerable State
    Fixed : Fixed State
    SecretOnly : Agent-Secret-Only State
    ImageOnly : Agent-Image-Only State

    Vulnerable --> Fixed : AI Remediation applied
    Vulnerable --> SecretOnly : reset-demo script
    Vulnerable --> ImageOnly : reset-demo script
    SecretOnly --> Fixed : After remediation
    ImageOnly --> Fixed : After remediation
    Fixed --> Vulnerable : Reset for demo re-seed
    Fixed --> [*] : Production push to Docker Hub
```

### 11.2 Demo Profile Comparison

| Profile | Folder | Dockerfile Base | `app.py` Secret | Validation Logic |
|---|---|---|---|---|
| `vulnerable` | `demo-states/vulnerable/` | `python:3.8` | Hardcoded literal | Duplicated inline |
| `fixed` | `demo-states/fixed/` | `python:3.12-slim` | `os.environ.get(...)` | `validate_note_input()` |
| `agent-secret-only` | `demo-states/agent-secret-only/` | `python:3.12-slim` | Hardcoded literal | Duplicated inline |
| `agent-image-only` | `demo-states/agent-image-only/` | `python:3.8` | `os.environ.get(...)` | `validate_note_input()` |

### 11.3 Reset Commands

```powershell
# Windows PowerShell
.\scripts\reset-demo.ps1 -State vulnerable
.\scripts\reset-demo.ps1 -State fixed
.\scripts\reset-demo.ps1 -State agent-secret-only
.\scripts\reset-demo.ps1 -State agent-image-only
```

```bash
# Linux / macOS / Git Bash
./scripts/reset-demo.sh vulnerable
./scripts/reset-demo.sh fixed
```

---

## 12. Environment Configuration

### 12.1 Required Secrets & API Keys

```mermaid
graph LR
    subgraph GitHub["GitHub Repo Secrets"]
        S1["SONAR_TOKEN\nSonarCloud auth token"]
        S2["SONAR_PROJECT_KEY\nUnique project identifier"]
        S3["SONAR_ORG\nOrganization key"]
        S4["DOCKERHUB_USERNAME\nDocker Hub account"]
        S5["DOCKERHUB_TOKEN\nRead/Write PAT"]
        S6["NVIDIA_API_KEY\nbuild.nvidia.com key"]
    end

    subgraph LocalEnv[".env local only"]
        E1["APP_SECRET_KEY\nRuntime Flask secret"]
        E2["FLASK_PORT\nDefault: 5000"]
    end

    S1 --> SonarCloud
    S2 --> SonarCloud
    S3 --> SonarCloud
    S4 --> DockerHub
    S5 --> DockerHub
    S6 --> NVIDIA_NIM["NVIDIA NIM API"]
    E1 --> FlaskApp["Flask Application"]
    E2 --> FlaskApp
```

### 12.2 Full Configuration Reference

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `SONAR_TOKEN` | Yes | — | SonarCloud authentication |
| `SONAR_PROJECT_KEY` | Yes | `Siddhantshukla1657_SecureNotes_Devops_Miniproject` | SonarCloud project identifier |
| `SONAR_ORG` | Yes | `siddhantshukla1657` | SonarCloud organization key |
| `DOCKERHUB_USERNAME` | Yes | — | Docker Hub account username |
| `DOCKERHUB_TOKEN` | Yes | — | Docker Hub R/W Access Token |
| `NVIDIA_API_KEY` | Yes | — | NVIDIA NIM API authentication |
| `NVIDIA_MODEL` | Optional | `nvidia/llama-3.1-nemotron-70b-instruct` | Target LLM model |
| `APP_SECRET_KEY` | Optional | `default-dev-key` | Flask session/auth key |
| `FLASK_PORT` | Optional | `5000` | HTTP listener port |

---

## 13. Data Flow & Request Lifecycle

### 13.1 End-to-End Developer Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant SC as SonarCloud
    participant Docker as Docker Engine
    participant Trivy as Trivy Scanner
    participant Hub as Docker Hub
    participant NIM as NVIDIA NIM API
    participant PR as Pull Request

    Dev->>GH: git push to main or PR
    GH->>GHA: Trigger pipeline.yml

    Note over GHA,SC: Stage 1 — Code Quality
    GHA->>GHA: pytest + coverage.xml
    GHA->>SC: sonarqube-scan-action upload results
    SC-->>GHA: Quality Gate result

    alt Quality Gate PASS
        GHA->>Docker: docker build sample-app:latest

        Note over Docker,Trivy: Stage 2 — Container Scan
        GHA->>Trivy: Scan sample-app:latest to JSON artifact
        GHA->>Trivy: Scan with exit-code 1 gate

        alt Zero HIGH/CRITICAL CVEs
            Note over GHA,Hub: Stage 3 — Publish
            GHA->>Hub: docker push username/securenotes:latest
            Hub-->>Dev: Image live on Docker Hub
        else CVEs Found
            Note over GHA,NIM: Stage 4 — Remediation
            GHA->>NIM: POST chat completions with Trivy findings
            NIM-->>GHA: Patch diff and explanation
            GHA->>PR: Create PR agent-fix/security-remediation
            PR-->>Dev: Review notification
            Dev->>PR: Review and approve
            PR->>GH: Merge to main and retrigger pipeline
        end
    else Quality Gate FAIL
        Note over GHA,NIM: Stage 4 — Remediation
        GHA->>SC: Fetch issue list via SonarCloud API
        GHA->>NIM: POST chat completions with SonarCloud findings
        NIM-->>GHA: Patch diff and explanation
        GHA->>PR: Create PR agent-fix/security-remediation
        PR-->>Dev: Review notification
        Dev->>PR: Review and approve
        PR->>GH: Merge to main and retrigger pipeline
    end
```

---

## 14. Security Analysis & Findings

### 14.1 Threat Model Overview

```mermaid
graph TD
    subgraph Threats["Identified Threat Vectors"]
        T1["Secret Exposure\nHardcoded API keys in source code\nleaked via git history"]
        T2["Supply Chain CVEs\nOutdated base OS packages\nwith published exploits"]
        T3["Input Injection\nUnvalidated note text\nXSS or overflow"]
        T4["Autonomous AI Risk\nAI agent self-merging\nwithout human review"]
    end

    subgraph Mitigations["Mitigations Implemented"]
        M1["SonarCloud S2068\nBlocks secrets at commit time"]
        M2["Trivy + python:3.12-slim + apt upgrade\nEliminate known CVEs"]
        M3["validate_note_input\nServer-side strip and non-empty check"]
        M4["Human-in-the-Loop PR Gate\nAgent can only open PRs not merge them"]
    end

    T1 --> M1
    T2 --> M2
    T3 --> M3
    T4 --> M4
```

### 14.2 Vulnerability Seeding Details

| Finding Type | Rule / CVE | Seeded Location | AI Fix Proposed |
|---|---|---|---|
| Hardcoded Secret | `python:S2068` | `app.py` — `API_KEY = "literal"` | Replace with `os.environ.get("APP_SECRET_KEY")` |
| Code Smell | Duplication | `add_note()` + `delete_note()` — inline validation | Extract `validate_note_input()` helper |
| Container CVE | Multiple HIGH | `FROM python:3.8` OS packages | Upgrade to `FROM python:3.12-slim` + `apt upgrade` |

---

## 15. Conclusion & Key Learnings

### 15.1 Project Summary

SecureNotes demonstrates a complete, production-inspired DevSecOps pipeline where security is not bolted-on after the fact, but is **integrated as a first-class concern at every stage of the software lifecycle**.

```mermaid
flowchart LR
    A["Shift-Left\nSecurity"] --> B["Automated\nGates"] --> C["AI-Assisted\nRemediation"] --> D["Human\nOversight"] --> E["Trusted\nDelivery"]
```

### 15.2 Key Technical Achievements

| Achievement | Implementation |
|---|---|
| **Zero-Trust Gate Pipeline** | Both SonarCloud AND Trivy must pass before publish |
| **AI-Powered Triage** | NVIDIA Nemotron 70B generates real, compilable patches |
| **Non-Autonomous AI** | Strict PR-only boundary; agent cannot push to main |
| **Repeatable Demos** | 4 seeded states + PowerShell/Bash reset scripts |
| **Full Test Harness** | 6 pytest cases, coverage.xml fed to SonarCloud |
| **Hardened Container** | `python:3.12-slim` + `apt upgrade` clears OS CVEs |

### 15.3 DevSecOps Maturity Indicators

| Maturity Dimension | Evidence |
|---|---|
| **Automation** | Full CI/CD with no manual build or scan steps |
| **Speed** | Secrets caught at Stage 1 before compute-heavy build |
| **AI Augmentation** | LLM reduces mean time to remediation for known patterns |
| **Compliance** | Audit trail via GitHub PR history and pipeline run logs |
| **Extensibility** | Mock mode enables offline testing of remediation agent |

---

> [!NOTE]
> This report was generated for the **SecureNotes DevOps Miniproject** — a demonstration of modern DevSecOps practices. All diagrams are rendered in Mermaid.js and are compatible with GitHub's native Markdown renderer.

---

*Report generated: October 2026 | Authors: Siddhant Shukla & Siddhant Raut | Repository: [github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject](https://github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject)*
