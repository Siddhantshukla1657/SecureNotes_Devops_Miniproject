# 🔒 SecureNotes — DevSecOps Secure CI/CD Pipeline & AI Remediation

**SecureNotes** is a complete, production-grade demonstration of **Shift-Left Security** and **Human-in-the-Loop AI Remediation** built with **Flask**, **Docker**, **SonarCloud**, **Trivy**, **GitHub Actions**, and **NVIDIA NIM (Nemotron)**.

The project demonstrates automated security gates protecting an application lifecycle before any artifacts reach a public registry, coupled with an AI remediation agent that autonomously generates reviewable Pull Requests for flagged vulnerabilities.

---

## 📑 Table of Contents
1. [Architecture & System Flow](#-architecture--system-flow)
2. [DevSecOps Security Gates & Shift-Left Model](#-devsecops-security-gates--shift-left-model)
3. [User & Remediation Flowcharts](#-user--remediation-flowcharts)
4. [Data Model](#-data-model)
5. [Required API Keys & Environment Variables](#-required-api-keys--environment-variables)
6. [Local Quickstart & Execution](#-local-quickstart--execution)
7. [Automated Testing Guide (Pytest)](#-automated-testing-guide-pytest)
8. [Docker Container Verification](#-docker-container-verification)
9. [AI Remediation Agent (NVIDIA Nemotron)](#-ai-remediation-agent-nvidia-nemotron)
10. [Repeatable Demo Profiles & Reset Tooling](#-repeatable-demo-profiles--reset-tooling)
11. [Step-by-Step Viva / Evaluation Runbook](#-step-by-step-viva--evaluation-runbook)

---

## 🏗️ Architecture & System Flow

The CI/CD pipeline enforces a strict multi-layer security barrier: source code must pass static code and secret scanning (SonarCloud) before compute is spent building a container image, and the resulting container image must pass vulnerability scanning (Trivy) before being published to Docker Hub. If any gate fails, the pipeline halts and branches to the NVIDIA Nemotron remediation agent.

```mermaid
graph TD
    Dev["👨‍💻 Developer (git push)"] --> GH["📦 GitHub Repository"]
    GH --> GA["⚙️ GitHub Actions CI/CD Pipeline"]
    
    subgraph "Stage 1: Code Security"
        GA --> J1["🔍 Job: code-quality"]
        J1 --> Tests["🧪 Run Pytest Suite"]
        Tests --> SC["📡 SonarCloud Static Analysis"]
        SC --> QG{"Quality Gate Passed?"}
    end
    
    subgraph "Stage 2: Container Security"
        QG -->|Yes| J2["🛡️ Job: build-and-scan"]
        J2 --> Build["🐳 Docker Build (sample-app:latest)"]
        Build --> Trivy["🔎 Trivy Vulnerability Scan"]
        Trivy --> CVECheck{"High/Critical CVEs?"}
    end
    
    subgraph "Stage 3: Registry Delivery"
        CVECheck -->|Zero Findings| J3["🚀 Job: publish"]
        J3 --> Login["🔑 Docker Hub Auth"]
        Login --> Push["📤 Push Image to Docker Hub"]
        Push --> Registry[("🌐 Docker Hub Registry")]
    end
    
    subgraph "Stage 4: Agentic Remediation"
        QG -->|No (Secret / Code Smell)| RA["🤖 Job: remediate"]
        CVECheck -->|Yes (Vulnerable Base)| RA
        RA --> NIM["🧠 NVIDIA NIM API (Nemotron 70B)"]
        NIM --> Patch["📝 Generate Scoped Patch & Explanation"]
        Patch --> PR["📬 Open GitHub Pull Request"]
        PR --> Review["👤 Developer Review & Approval"]
        Review -->|Merge PR| GH
    end
```

---

## 🛡️ DevSecOps Security Gates & Shift-Left Model

The pipeline implements "Shift-Left" security by catching flaws as early as possible in the lifecycle:

```mermaid
flowchart LR
    A["1. Code Creation"] --> B["2. Static & Secret Gate (SonarCloud)"]
    B -->|Blocked on Secrets/Smells| Rem1["AI Remediation PR"]
    B -->|Clean| C["3. Container Build"]
    C --> D["4. Image CVE Gate (Trivy)"]
    D -->|Blocked on OS CVEs| Rem2["AI Remediation PR"]
    D -->|Clean| E["5. Trusted Registry (Docker Hub)"]
```

### Security Layers Enforced:
1. **Code Layer (SonarCloud)**:
   - **Hardcoded Secret Detection**: Catches plaintext API credentials, access tokens, and private keys.
   - **Code Smell & Maintainability Analysis**: Flags duplicated validation logic and non-standard constructs.
   - **Quality Gate Gating**: Strictly halts the pipeline if SonarCloud Quality Gate fails.
2. **Container Layer (Trivy)**:
   - **OS Package & Dependency CVE Scanning**: Scans container layers for known public CVEs (e.g. vulnerable end-of-life `python:3.8` base images).
   - **Severity Threshold**: Configured with `exit-code: 1` on `HIGH` or `CRITICAL` findings.
3. **AI Remediation Boundary (Human-in-the-Loop)**:
   - The NVIDIA Nemotron agent is **strictly non-autonomous** regarding repository merges.
   - Workflow permissions are restricted to opening a Pull Request with a proposed diff and plain-language explanation; a human developer must review and merge every fix.

---

## 🔄 User & Remediation Flowcharts

### 1. Add Note User Flow
```mermaid
flowchart TD
    Start["User navigates to http://localhost:5000"] --> View["View active notes & form"]
    View --> Input["User types note text and submits form"]
    Input --> Valid{"Is note non-empty?"}
    Valid -->|No| Reject["Reject input & reload page safely"]
    Valid -->|Yes| Store["Generate UUID & prepend to in-memory store"]
    Store --> Render["Re-render notes grid with timestamp & delete button"]
    Reject --> View
    Render --> View
```

### 2. Delete Note User Flow
```mermaid
flowchart TD
    Start["User views active note card"] --> Click["Click 'Delete' button"]
    Click --> Post["POST request sent to /delete/id"]
    Post --> Exists{"Does note id exist in memory?"}
    Exists -->|Yes| Remove["Remove note from store (slice mutation)"]
    Exists -->|No| Ignore["Safe no-op redirect"]
    Remove --> Refresh["Re-render updated list"]
    Ignore --> Refresh
```

### 3. Agentic Remediation & Human Review Flow
```mermaid
flowchart TD
    Fail["Pipeline Gate Fails (Code or Image)"] --> Trigger["remediate job launches"]
    Trigger --> Extract["Extract finding from SonarCloud API or Trivy JSON"]
    Extract --> Prompt["Construct scoped prompt with current file content"]
    Prompt --> NIM["Send to NVIDIA NIM API (llama-3.1-nemotron-70b-instruct)"]
    NIM --> Parse["Parse JSON response: diff + title + explanation"]
    Parse --> Branch["Create branch: agent-fix/security-remediation"]
    Branch --> CreatePR["Open Pull Request via peter-evans/create-pull-request"]
    CreatePR --> DevReview["👨‍💻 Human Developer reviews diff and explanation"]
    DevReview --> Decision{"Approve & Merge?"}
    Decision -->|Yes| Merge["Merge PR into main"]
    Decision -->|No| Close["Close PR / manual tweak"]
    Merge --> NewRun["Fresh CI/CD pipeline triggered on main (Passes!)"]
```

---

## 🗄️ Data Model

The application uses an ephemeral in-memory store for the lifecycle of the container:

```mermaid
erDiagram
    NOTE {
        string id PK "Unique identifier (UUID prefix)"
        string text "Note content string"
        string created_at "Formatted timestamp (YYYY-MM-DD HH:MM:SS)"
    }
```

---

## 🔑 Required API Keys & Environment Variables

All API keys and configuration parameters are centralized in [.env.example](file:///c:/Users/Siddhant/Documents/GitHub/SecureNotes_Devops_Miniproject/.env.example). 

### Configuration Table:

| Variable / Secret | Where to Obtain | Purpose |
|---|---|---|
| `SONAR_TOKEN` | [SonarCloud Security Tokens](https://sonarcloud.io/account/security/) | Static code scan authentication & quality gate check |
| `SONAR_PROJECT_KEY` | SonarCloud Project Overview | Unique project key (`Siddhantshukla1657_SecureNotes_Devops_Miniproject`) |
| `SONAR_ORG` | SonarCloud Organization Page | Organization key (`siddhantshukla1657`) |
| `DOCKERHUB_USERNAME` | [Docker Hub](https://hub.docker.com) | Account username for container registry |
| `DOCKERHUB_TOKEN` | [Docker Hub Access Tokens](https://hub.docker.com/settings/security) | Read/Write Personal Access Token |
| `NVIDIA_API_KEY` | [NVIDIA NIM (build.nvidia.com)](https://build.nvidia.com) | Free API key for `nvidia/llama-3.1-nemotron-70b-instruct` |
| `NVIDIA_MODEL` | Set by default in `.env.example` | Target model: `nvidia/llama-3.1-nemotron-70b-instruct` |
| `APP_SECRET_KEY` | Local / Runtime | Runtime secret key for authentication |

### Setting Up GitHub Repository Secrets:
1. In your GitHub repository, open **Settings > Secrets and variables > Actions**.
2. Click **New repository secret** and add `SONAR_TOKEN`, `SONAR_PROJECT_KEY`, `SONAR_ORG`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, and `NVIDIA_API_KEY`.
3. Under **Settings > Actions > General > Workflow permissions**:
   - Choose **Read and write permissions**.
   - Check **Allow GitHub Actions to create and approve pull requests**.

---

## 🚀 Local Quickstart & Execution

### Option 1: 1-Click Batch File (Windows)
Double-click **[run.bat](file:///c:/Users/Siddhant/Documents/GitHub/SecureNotes_Devops_Miniproject/run.bat)** or run in Command Prompt:
```cmd
run.bat
```
*This automatically verifies Python, activates your virtual environment if present, installs requirements, opens `http://localhost:5000` in your default browser, and launches the server.*

---

### Option 2: Manual Terminal Setup

```bash
# 1. Clone repository
git clone https://github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject.git
cd SecureNotes_Devops_Miniproject

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
# On Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# On Linux / macOS:
source venv/bin/activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Copy environment template
cp .env.example .env

# 6. Run the application
python app.py
```
Open **[http://localhost:5000](http://localhost:5000)** in your browser.

---

## 🧪 Automated Testing Guide (Pytest)

The project includes an automated test suite verifying all routes, input validations, and error conditions.

### Run Automated Tests:
```bash
pytest tests/ -v
```

### Test Coverage Summary:
- `test_health_check`: Verifies `GET /health` returns `200 OK` and `{"status": "ok", "service": "securenotes"}`.
- `test_index_page`: Verifies `GET /` correctly renders HTML with the Pico.css header and note list.
- `test_add_note_success`: Verifies `POST /add` creates new notes in memory and redirects to index.
- `test_add_note_empty_rejected`: Verifies whitespace/empty submissions are rejected without data corruption.
- `test_delete_note_success`: Verifies `POST /delete/<id>` deletes the note by ID.
- `test_delete_note_nonexistent`: Verifies non-existent IDs do not cause exceptions.

---

## 🐳 Docker Container Verification

### Build & Run Container Locally:
```bash
# Build Docker image
docker build -t securenotes:local .

# Run the container
docker run -d -p 5000:5000 --name securenotes-container securenotes:local

# Test container health endpoint
curl http://localhost:5000/health

# Stop and remove container
docker stop securenotes-container && docker rm securenotes-container
```

---

## 🤖 AI Remediation Agent (NVIDIA Nemotron)

The remediation agent located at `scripts/remediate_agent.py` can be tested locally in offline mock mode or with live NVIDIA NIM credentials.

### Test Code Remediation (Hardcoded Secret & Code Smell):
```bash
python scripts/remediate_agent.py --finding-type code --mock
```
*Effect: Replaces hardcoded `API_KEY` in `app.py` with environment variable loading, extracts unified `validate_note_input()` helper, and writes `pr_title.txt` & `pr_body.md`.*

### Test Image Remediation (Base Image CVEs):
```bash
python scripts/remediate_agent.py --finding-type image --mock
```
*Effect: Upgrades `Dockerfile` base image from `python:3.8` to `python:3.12-slim` and writes PR metadata.*

---

## 🎯 Repeatable Demo Profiles & Reset Tooling

Four pre-configured demo profiles exist under `demo-states/` to enable rapid, repeatable demonstrations during evaluations:

```mermaid
graph LR
    A["demo-states/"] --> B["vulnerable: python:3.8 + hardcoded secret + duplicate validation"]
    A --> C["fixed: python:3.12-slim + env var auth + helper validation"]
    A --> D["agent-secret-only: isolated secret on clean base"]
    A --> E["agent-image-only: clean app on vulnerable python:3.8 base"]
```

### Switching Demo Profiles:

**On Windows (PowerShell):**
```powershell
# Restore vulnerable baseline locally:
.\scripts\reset-demo.ps1 -State vulnerable

# Restore vulnerable baseline and automatically push to GitHub:
.\scripts\reset-demo.ps1 -State vulnerable -Push

# Restore completely fixed state:
.\scripts\reset-demo.ps1 -State fixed -Push
```

**On Linux / macOS / Git Bash:**
```bash
# Restore state locally:
./scripts/reset-demo.sh vulnerable

# Restore and push to GitHub:
./scripts/reset-demo.sh vulnerable --push
```

---

## 📋 Step-by-Step Viva / Evaluation Runbook

### Stage 1 — Demonstrate Failing Security Gates
1. Push the vulnerable baseline:
   ```powershell
   .\scripts\reset-demo.ps1 -State vulnerable -Push
   ```
2. Open GitHub repository **Actions** tab.
3. Show the pipeline failing at the **Code Quality & Secret Scan** stage with SonarCloud identifying the hardcoded secret `sk-test-12345` and duplicated validation logic.

### Stage 2 — Demonstrate AI Remediation & Human Review
1. In the same failed workflow run, show the **remediate** job executing.
2. Navigate to the repository **Pull Requests** tab.
3. Open the newly created PR by the agent (`agent-fix/security-remediation`).
4. Show the evaluator the Nemotron-generated PR description, explanation of why the finding was dangerous, and the clean proposed diff.
5. **Key Talking Point**: Highlight the **Human-in-the-Loop boundary** — the agent proposes fixes via Pull Request but is structurally prevented from auto-merging into `main`.

### Stage 3 — Review and Merge Fix
1. Click **Merge pull request** on GitHub.
2. The merge commit to `main` automatically triggers a new pipeline run.

### Stage 4 — Demonstrate Green End-to-End Pipeline & Publishing
1. Watch the new workflow run on `main`:
   - `code-quality`: **PASS** (SonarCloud Quality Gate clears).
   - `build-and-scan`: **PASS** (Trivy scans `python:3.12-slim` with zero high/critical CVEs).
   - `publish`: **PASS** (Image is authenticated, tagged, and published to Docker Hub).
2. Open Docker Hub and show the newly published image `securenotes:latest`.
