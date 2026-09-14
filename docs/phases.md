# SecureNotes Secure CI Pipeline — Phases

> **Status:** Draft | **Last updated:** September 14, 2026

## Roadmap Summary
| Phase | Name | Goal | Target duration |
|---|---|---|---|
| Phase 1 | App & Vulnerable Baseline | A working SecureNotes UI runs in a container, with real, intentional code and image issues in place | 1–2 days |
| Phase 2 | Code Quality Gate | GitHub Actions runs a SonarCloud scan on every push and blocks the pipeline on the seeded issues | 1 day |
| Phase 3 | Image Vulnerability Gate | Pipeline builds the Docker image and blocks on Trivy-detected HIGH/CRITICAL CVEs | 1 day |
| Phase 4 | Remediation & Green Pipeline | All seeded issues are fixed manually, the full pipeline passes end-to-end, and the image is published | 1 day |
| Phase 5 | Automated Remediation Agent | A Nemotron-powered agent reads failed scan findings, proposes a fix, and opens a PR for developer review | 1–2 days |

---

## Phase 1: App & Vulnerable Baseline
**Goal:** SecureNotes runs locally and in Docker with a real UI, and contains the three intentional issues the scanners are meant to catch.

**Scope:**
- Build the Flask app: `GET /`, `POST /add`, `POST /delete/<id>`, `GET /health`.
- Build the Jinja2 template + Pico.css-based UI (note cards, add form, delete button).
- Write the Dockerfile using `python:3.8` as the base image.
- Add the hardcoded `API_KEY` constant guarding the add/delete routes.
- Duplicate the note-validation logic between `/add` and `/delete` instead of extracting a shared helper.
- Verify the app builds and runs correctly in Docker locally (`docker build`, `docker run`, confirm UI loads).

**Out of scope for this phase:**
- Any CI/CD automation — this phase is local only.
- Any security fixes — the issues are intentional and must remain until Phase 4.

**Deliverables:**
- Working SecureNotes app, runnable via `docker run`.
- Dockerfile, `app.py`, `templates/index.html`, `static/style.css`, `requirements.txt`.

**Dependencies:** None — this is the starting point.

**Exit criteria:** The app runs in a container, the UI is fully functional (add/list/delete notes), and all three intentional issues are confirmed present in the code.

---

## Phase 2: Code Quality Gate
**Goal:** Every push triggers a SonarCloud scan, and the pipeline fails when the seeded secret and code smell are detected.

**Scope:**
- Create a SonarCloud project linked to the GitHub repository.
- Add `SONAR_TOKEN` as a GitHub Actions secret.
- Write the `code-quality` job in `.github/workflows/pipeline.yml` using `sonarsource/sonarqube-scan-action` and the Quality Gate check action.
- Trigger a push and confirm the job fails at the Quality Gate due to the hardcoded secret and duplicated logic.
- Capture a screenshot/log of the failed run for the final report.

**Out of scope for this phase:**
- Docker build or Trivy scanning — those belong to Phase 3.
- Fixing any of the flagged issues — that happens in Phase 4.
- Any agent involvement — that's Phase 5.

**Deliverables:**
- Working `code-quality` job in the GitHub Actions workflow.
- SonarCloud dashboard showing the hardcoded secret and code smell findings.
- Evidence of a failed pipeline run.

**Dependencies:** Phase 1 (the app and its seeded issues must exist).

**Exit criteria:** A push to `main` triggers the workflow, and the `code-quality` job fails with SonarCloud correctly identifying both the hardcoded secret and the duplicated validation logic.

---

## Phase 3: Image Vulnerability Gate
**Goal:** The pipeline builds the Docker image and blocks progression when Trivy finds HIGH or CRITICAL CVEs in the `python:3.8` base image.

**Scope:**
- Add the `build-and-scan` job, gated with `needs: code-quality`.
- Add the Docker build step.
- Add the Trivy scan step (`aquasecurity/trivy-action`) with `severity: HIGH,CRITICAL` and `exit-code: 1`.
- Temporarily allow the `code-quality` job to pass (or run this job in isolation) to confirm Trivy independently fails on the vulnerable base image.
- Record the CVE count and a sample of flagged CVEs for the results table.

**Out of scope for this phase:**
- The `publish` job — that's Phase 4.
- Any base image changes — the vulnerable image must remain until Phase 4's remediation step.
- Any agent involvement — that's Phase 5.

**Deliverables:**
- Working `build-and-scan` job.
- Logged Trivy output showing HIGH/CRITICAL CVE count on `python:3.8`.

**Dependencies:** Phase 2 (the `code-quality` job must exist so the `needs:` dependency chain is meaningful).

**Exit criteria:** The `build-and-scan` job builds the image successfully and then fails due to Trivy detecting HIGH/CRITICAL CVEs.

---

## Phase 4: Remediation & Green Pipeline
**Goal:** All seeded issues are fixed manually, every stage of the pipeline passes, and the final image is published to Docker Hub. This phase establishes the manual "ground truth" fixes before Phase 5 automates the same kind of remediation.

**Scope:**
- Remediation Round 1 (code layer): remove the hardcoded `API_KEY`, move it to a GitHub Actions secret / environment variable, and extract the duplicated validation logic into a shared helper function.
- Re-run the pipeline and confirm the `code-quality` job now passes.
- Remediation Round 2 (image layer): switch the Dockerfile's base image from `python:3.8` to `python:3.12-slim`.
- Re-run the pipeline and confirm the `build-and-scan` job now passes with zero HIGH/CRITICAL CVEs.
- Add the `publish` job (Docker Hub login + build + push), gated with `needs: build-and-scan`.
- Run the full pipeline end-to-end and confirm all four stages pass, ending with the image live on Docker Hub.
- Compile the before/after results table and screenshots for the final report.

**Out of scope for this phase:**
- Any new features for the SecureNotes app itself.
- The automated agent path — that's Phase 5, built on top of this baseline.

**Deliverables:**
- Fully green pipeline run (all four stages passing).
- Published image on Docker Hub.
- Before/after results table (bugs, code smells, secrets, CVEs) for the report.

**Dependencies:** Phases 1–3 (all issues and gates must already exist to have something to remediate against).

**Exit criteria:** A single push triggers all four stages, all pass, and the final image is confirmed live on Docker Hub.

---

## Phase 5: Automated Remediation Agent
**Goal:** When either gate fails, an agent automatically proposes a fix using Nemotron (via the NVIDIA NIM API) and opens a pull request for developer review — demonstrating human-in-the-loop agentic remediation on top of the manual baseline from Phase 4.

**Scope:**
- Sign up for a free NVIDIA developer account at build.nvidia.com and generate an API key.
- Add `NVIDIA_API_KEY` as a GitHub Actions secret.
- Reintroduce one seeded issue (e.g. re-add the hardcoded secret on a new branch, or revert the base image) to have a real failure for the agent to act on.
- Add a `remediate` job to the workflow, triggered when `code-quality` or `build-and-scan` fails.
- In the `remediate` job: extract the relevant finding (SonarCloud issue JSON or Trivy CVE JSON), send it to Nemotron via `https://integrate.api.nvidia.com/v1/chat/completions` with a scoped prompt asking for a minimal diff and a short explanation.
- Apply the returned diff to a new branch and use `peter-evans/create-pull-request` to open a PR containing the diff and the agent's explanation.
- Manually review the opened PR: confirm the diff is correct (or note where it isn't, for an honest report), then merge it.
- Confirm merging the PR triggers a fresh pipeline run that now passes the previously-failing gate.
- Document the agent's boundary explicitly in the report: it opens PRs only, never pushes to `main`, and never merges its own PR.
- Build a repeatable demo reset tool (`scripts/reset-demo.sh` + `demo-states/`) so any of the four states — fully vulnerable, fully fixed, secret-only, or image-only — can be reintroduced on demand with one command, since this pipeline will be demonstrated more than once (grading, viva, rehearsal).

**Out of scope for this phase:**
- Auto-merging any agent-proposed PR — this must always require a human decision.
- Handling every possible finding type — one or two representative cases (e.g. the hardcoded secret and the base image CVE) are enough to demonstrate the pattern.

**Deliverables:**
- Working `remediate` job in the workflow.
- At least one real, reviewable pull request opened by the agent, with a correct or explainably-imperfect proposed fix.
- Documentation of the human-in-the-loop boundary for the final report.
- `scripts/reset-demo.sh` plus `demo-states/{vulnerable,fixed,agent-secret-only,agent-image-only}/`, so any demo state can be restored with a single command instead of manually re-editing files before each run.

**Dependencies:** Phase 4 (the manual remediation baseline should exist first, so the agent's automated fix can be compared against a known-correct manual fix).

**Exit criteria:** A gate failure triggers the `remediate` job, a pull request is opened with a diff and explanation, merging that PR results in a passing pipeline on the next run, and any of the four demo states can be restored with a single `reset-demo.sh` command for a repeat run.

---

## Future / Not Yet Scheduled
- SARIF report upload to GitHub's Security tab for both SonarCloud and Trivy findings.
- `.trivyignore` handling for any genuinely unfixable CVE, with documented justification.
- Persistent storage (real database) for the SecureNotes app, if extended beyond this assignment.
- Extending the remediation agent to handle a wider range of finding types beyond the two demonstrated cases.
