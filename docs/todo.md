# SecureNotes Secure CI Pipeline — Todo

> **Last updated:** September 14, 2026 | **Authors:** Siddhant Shukla & Siddhant Raut. Check items off as they're completed; keep this file in sync with actual progress.

## Phase 1: App & Vulnerable Baseline
- [x] Scaffold the Flask app (`app.py`) with `GET /`, `POST /add`, `POST /delete/<id>`, `GET /health`
- [x] Build the Jinja2 template (`templates/index.html`) with add-note form and note-card list
- [x] Add `static/style.css` and link Pico.css via CDN for base styling
- [x] Add the header + "Secure Pipeline Demo" badge to the UI
- [x] Implement the in-memory notes store (id, text, created_at)
- [x] Seed the hardcoded `API_KEY` constant in `app.py`
- [x] Seed the duplicated validation logic across `/add` and `/delete`
- [x] Write the Dockerfile using `python:3.8` as the base image
- [x] Build the image locally and confirm the UI loads and add/delete work end-to-end
- [x] Confirm `/health` returns a 200 response from the running container

## Phase 2: Code Quality Gate
- [x] Create a SonarCloud configuration (`sonar-project.properties`)
- [x] Document `SONAR_TOKEN` (and `SONAR_HOST_URL` if required) in `.env.example`
- [x] Write `.github/workflows/pipeline.yml` with the `code-quality` job
- [ ] Push to `main` and confirm the SonarCloud scan runs (cloud step)
- [ ] Confirm the Quality Gate fails due to the seeded secret and code smell (cloud step)
- [ ] Screenshot/log the failed run and the SonarCloud dashboard findings (evaluation step)

## Phase 3: Image Vulnerability Gate
- [x] Add the `build-and-scan` job (`needs: code-quality`) to the workflow
- [x] Add the Docker build step (`docker build -t sample-app:latest .`)
- [x] Add the Trivy scan step with `severity: HIGH,CRITICAL` and `exit-code: 1`
- [ ] Confirm the job builds successfully, then fails at the Trivy step (cloud step)
- [ ] Record the CVE count and a few example CVEs from the Trivy output (evaluation step)

## Phase 4: Remediation & Green Pipeline
- [x] Create clean remediated baseline snapshot in `demo-states/fixed/`
- [x] Extract the duplicated validation logic into a shared helper function (`validate_note_input`)
- [x] Switch the Dockerfile's base image to `python:3.12-slim` in fixed snapshot
- [x] Add the `publish` job (`needs: build-and-scan`) with Docker Hub login, build, and push steps
- [x] Document `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` in `.env.example`
- [ ] Run the full pipeline end-to-end and confirm all four stages pass (cloud step)
- [ ] Confirm the final image is live on Docker Hub (cloud step)

## Phase 5: Automated Remediation Agent
- [x] Document `NVIDIA_API_KEY` setup in `.env.example`
- [x] Add the `remediate` job to the workflow, triggered on failure of `code-quality` or `build-and-scan`
- [x] Implement finding extraction (SonarCloud issues API and Trivy JSON output) in `scripts/remediate_agent.py`
- [x] Implement the Nemotron API call (via NVIDIA NIM) with structured JSON prompt
- [x] Implement offline/simulation mode for testing without credits (`--mock`)
- [x] Add `peter-evans/create-pull-request` step to open the PR with the diff and explanation
- [x] Scope the `remediate` job's permissions to `pull-requests: write` / `contents: write` (human-in-the-loop boundary)
- [x] Build `demo-states/{vulnerable,fixed,agent-secret-only,agent-image-only}/` snapshots
- [x] Write `scripts/reset-demo.sh` (Bash) and `scripts/reset-demo.ps1` (PowerShell)
- [x] Test demo reset scripts and remediation dry-run locally

## Backlog / Unscheduled
- [ ] Upload SARIF reports from SonarCloud/Trivy to GitHub's Security tab
- [ ] Document `.trivyignore` usage if a genuinely unfixable CVE is found
- [ ] Consider persistent storage (real database) if the app is extended beyond this assignment
- [ ] Extend the remediation agent to handle more than one finding type per run
