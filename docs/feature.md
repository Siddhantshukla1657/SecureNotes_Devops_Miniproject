# SecureNotes Secure CI Pipeline — Feature List

> **Status:** Draft | **Last updated:** September 14, 2026

## Feature Summary
| # | Feature | Category | Phase | Priority | Status |
|---|---|---|---|---|---|
| 1 | Add note | App UI | Phase 1 | Must-have | Planned |
| 2 | List notes | App UI | Phase 1 | Must-have | Planned |
| 3 | Delete note | App UI | Phase 1 | Must-have | Planned |
| 4 | Health check endpoint | App | Phase 1 | Must-have | Planned |
| 5 | Seeded hardcoded secret | Vulnerability seeding | Phase 1 | Must-have | Planned |
| 6 | Seeded duplicated logic | Vulnerability seeding | Phase 1 | Must-have | Planned |
| 7 | Seeded vulnerable base image | Vulnerability seeding | Phase 1 | Must-have | Planned |
| 8 | SonarCloud code scan stage | CI/CD Security | Phase 2 | Must-have | Planned |
| 9 | Quality Gate enforcement | CI/CD Security | Phase 2 | Must-have | Planned |
| 10 | Docker image build stage | CI/CD | Phase 3 | Must-have | Planned |
| 11 | Trivy vulnerability scan stage | CI/CD Security | Phase 3 | Must-have | Planned |
| 12 | Code-layer remediation | Security fix | Phase 4 | Must-have | Planned |
| 13 | Image-layer remediation | Security fix | Phase 4 | Must-have | Planned |
| 14 | Publish to Docker Hub | CI/CD | Phase 4 | Must-have | Planned |
| 15 | Finding extraction for the agent | CI/CD Automation | Phase 5 | Must-have | Planned |
| 16 | Nemotron-based fix generation | CI/CD Automation | Phase 5 | Must-have | Planned |
| 17 | Agent pull request creation | CI/CD Automation | Phase 5 | Must-have | Planned |
| 18 | Human review boundary enforcement | CI/CD Automation | Phase 5 | Must-have | Planned |
| 19 | Repeatable demo reset tooling | Demo Tooling | Phase 5 | Must-have | Planned |

*Priority: Must-have / Should-have / Nice-to-have. Status: Planned / In progress / Done.*

---

## 1. Add note
**Category:** App UI
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
Lets a user type a short note into a form on the page and submit it to be added to the visible list.

**User story:**
As Siddhant (demoing the app), I want to add a note through the UI, so that the app looks like a real product during the pipeline demo.

**How it works:**
1. Trigger: user types text into the input field and clicks "Add Note".
2. Logic: `POST /add` receives the form data, validates the note isn't empty (this validation is duplicated with `/delete` — see Feature 6), generates an id, and appends the note to the in-memory list.
3. Result: the page re-renders showing the updated note list, including the new note.

**Inputs:** Note text (string) from the form field.

**Outputs:** Updated in-memory notes list; re-rendered HTML page.

**Edge cases & error handling:**
- Edge case: empty note submitted → rejected, page re-renders with no change and no note added.
- Error case: extremely long note text → currently unhandled; accepted as-is (acceptable for demo scope).

**Dependencies:** In-memory notes store.

---

## 2. List notes
**Category:** App UI
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
Displays all current notes as cards on the home page.

**User story:**
As an evaluator, I want to see the app's actual state visually, so that I can confirm the container is running a real, working service.

**How it works:**
1. Trigger: any `GET /` request (page load or after add/delete).
2. Logic: Flask reads the in-memory notes list and passes it to the Jinja2 template.
3. Result: each note renders as a styled card with its text and a delete button.

**Inputs:** None (reads current in-memory state).

**Outputs:** Rendered HTML page with note cards.

**Edge cases & error handling:**
- Edge case: no notes exist → page shows an empty-state message instead of an empty area.

**Dependencies:** In-memory notes store.

---

## 3. Delete note
**Category:** App UI
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
Removes a specific note from the list when its delete button is clicked.

**User story:**
As Siddhant, I want to delete a note, so that the demo can show a full CRUD-style interaction, not just adding.

**How it works:**
1. Trigger: user clicks "Delete" on a specific note card.
2. Logic: `POST /delete/<id>` receives the note id, validates it exists (this validation is duplicated with `/add` — see Feature 6), and removes it from the in-memory list.
3. Result: the page re-renders without the deleted note.

**Inputs:** Note id (from the delete button's form action).

**Outputs:** Updated in-memory notes list; re-rendered HTML page.

**Edge cases & error handling:**
- Edge case: id doesn't exist (e.g. double-click) → no-op, page re-renders unchanged.

**Dependencies:** In-memory notes store.

---

## 4. Health check endpoint
**Category:** App
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
Returns a simple 200 OK response confirming the running container is alive and serving requests.

**User story:**
As Siddhant, I want a `/health` endpoint, so that I can quickly prove the container built from the final pipeline run is actually functional.

**How it works:**
1. Trigger: `GET /health`.
2. Logic: returns a static JSON response, e.g. `{"status": "ok"}`.
3. Result: caller receives confirmation the app is running.

**Inputs:** None.

**Outputs:** JSON status response.

**Edge cases & error handling:** None applicable — this is a static response.

**Dependencies:** None.

---

## 5. Seeded hardcoded secret
**Category:** Vulnerability seeding
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
A hardcoded `API_KEY` constant is embedded directly in `app.py`, intended to simulate a real-world secrets-in-code mistake for SonarCloud to detect.

**User story:**
As Siddhant, I want a real hardcoded secret in the codebase, so that the code-scan gate has something genuine to catch and the report's "before" numbers are real.

**How it works:**
1. Trigger: none — this is a static code condition, not a runtime feature.
2. Logic: `API_KEY = "sk-test-12345"` is declared as a module-level constant and referenced by the add/delete routes as a stand-in for auth.
3. Result: SonarCloud's secret-detection rule flags this constant during the code-quality scan.

**Inputs:** None.

**Outputs:** A flagged finding in the SonarCloud dashboard.

**Edge cases & error handling:** Not applicable.

**Dependencies:** None.

---

## 6. Seeded duplicated logic
**Category:** Vulnerability seeding
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
The same note-validation check (confirming a note/id isn't empty) is written out separately in both the `/add` and `/delete` route handlers instead of being extracted into one shared helper function.

**User story:**
As Siddhant, I want a real duplicated-logic code smell, so that SonarCloud's code-smell detection has a genuine finding to report.

**How it works:**
1. Trigger: none — static code condition.
2. Logic: both routes independently contain the same `if not value: return redirect(...)`-style check.
3. Result: SonarCloud's duplication/code-smell rules flag this during the scan.

**Inputs:** None.

**Outputs:** A flagged code-smell finding in the SonarCloud dashboard.

**Edge cases & error handling:** Not applicable.

**Dependencies:** None.

---

## 7. Seeded vulnerable base image
**Category:** Vulnerability seeding
**Phase:** Phase 1
**Priority:** Must-have

**What it does:**
The Dockerfile initially uses `python:3.8` as its base image — an end-of-life version with real, published CVEs — so Trivy has genuine findings rather than staged ones.

**User story:**
As Siddhant, I want a real vulnerable base image, so that the "before" CVE count in the results table reflects an actual scan, not a fabricated number.

**How it works:**
1. Trigger: none — static Dockerfile condition.
2. Logic: `FROM python:3.8` at the top of the Dockerfile.
3. Result: when the image is built and scanned, Trivy reports the base image's known HIGH/CRITICAL CVEs.

**Inputs:** None.

**Outputs:** A CVE list in the Trivy scan output.

**Edge cases & error handling:** Not applicable.

**Dependencies:** None.

---

## 8. SonarCloud code scan stage
**Category:** CI/CD Security
**Phase:** Phase 2
**Priority:** Must-have

**What it does:**
Runs a static analysis scan of the source code on every push to `main`, as the first stage of the pipeline.

**User story:**
As an evaluator, I want to see an automated code-scan stage run on every commit, so that I can confirm shift-left security is actually implemented, not just described.

**How it works:**
1. Trigger: a `push` to the `main` branch.
2. Logic: the `code-quality` job checks out the code and runs `sonarsource/sonarqube-scan-action`, sending results to SonarCloud using the `SONAR_TOKEN` secret.
3. Result: SonarCloud records the scan and computes a Quality Gate result.

**Inputs:** Source code, `SONAR_TOKEN` secret.

**Outputs:** Scan results and Quality Gate status visible in the SonarCloud dashboard.

**Edge cases & error handling:**
- Error case: invalid or missing `SONAR_TOKEN` → job fails with an authentication error rather than a Quality Gate failure — must be distinguished when interpreting a failed run.

**Dependencies:** SonarCloud project must exist and be linked to the repository.

---

## 9. Quality Gate enforcement
**Category:** CI/CD Security
**Phase:** Phase 2
**Priority:** Must-have

**What it does:**
Blocks the pipeline from proceeding to the build stage if SonarCloud's Quality Gate does not pass.

**User story:**
As an evaluator, I want the pipeline to actually stop on a real failure, so that the "gate" isn't just cosmetic.

**How it works:**
1. Trigger: runs immediately after the code scan, within the same `code-quality` job.
2. Logic: `sonarsource/sonarqube-quality-gate-action` polls the Quality Gate result for the just-completed scan.
3. Result: if the gate status is "Failed" (e.g. due to the seeded secret or code smell), the job exits with a non-zero status, and downstream jobs (`build-and-scan`, `publish`) never run due to their `needs:` dependency — instead, the `remediate` job runs (see Feature 15).

**Inputs:** Quality Gate result from the prior scan step.

**Outputs:** Job success/failure status, which determines whether later jobs run.

**Edge cases & error handling:**
- Edge case: Quality Gate result takes longer than expected to compute → action polls with a timeout; a very slow SonarCloud response could cause a false failure (rare in practice).

**Dependencies:** Feature 8 (SonarCloud code scan stage).

---

## 10. Docker image build stage
**Category:** CI/CD
**Phase:** Phase 3
**Priority:** Must-have

**What it does:**
Builds the SecureNotes Docker image from the Dockerfile, but only after the code-quality gate has passed.

**User story:**
As Siddhant, I want the image build to only happen after code passes its checks, so that time isn't wasted building images from code that already failed review.

**How it works:**
1. Trigger: the `build-and-scan` job starts once `code-quality` succeeds (`needs: code-quality`).
2. Logic: `docker build -t sample-app:latest .` runs on the checked-out code.
3. Result: a local image, `sample-app:latest`, is available to the next step (Trivy scan) within the same job.

**Inputs:** Repository source, Dockerfile.

**Outputs:** Built Docker image (ephemeral, local to the runner).

**Edge cases & error handling:**
- Error case: Dockerfile syntax or dependency install failure → job fails before Trivy ever runs.

**Dependencies:** Feature 9 (Quality Gate enforcement must have passed).

---

## 11. Trivy vulnerability scan stage
**Category:** CI/CD Security
**Phase:** Phase 3
**Priority:** Must-have

**What it does:**
Scans the just-built Docker image for known CVEs and fails the job if any HIGH or CRITICAL severity issues are found.

**User story:**
As an evaluator, I want to see the image-layer gate independently catch a real vulnerability, so that I can confirm both layers of the pipeline (code and image) are genuinely enforced.

**How it works:**
1. Trigger: runs immediately after the Docker build step, within the same `build-and-scan` job.
2. Logic: `aquasecurity/trivy-action` scans `sample-app:latest` with `severity: HIGH,CRITICAL` and `exit-code: 1`.
3. Result: if any HIGH/CRITICAL CVEs are found, the job exits with a failure, and the `publish` job (which depends on `build-and-scan`) never runs — instead, the `remediate` job runs (see Feature 15).

**Inputs:** The built Docker image.

**Outputs:** CVE report (visible in the Actions log); job success/failure status.

**Edge cases & error handling:**
- Edge case: a CVE with no available fix exists in even the patched base image → would require a documented `.trivyignore` exception (see Future/Not Yet Scheduled in phases.md).

**Dependencies:** Feature 10 (Docker image build stage).

---

## 12. Code-layer remediation
**Category:** Security fix
**Phase:** Phase 4
**Priority:** Must-have

**What it does:**
Fixes the seeded hardcoded secret and duplicated logic so the code-quality gate passes.

**User story:**
As Siddhant, I want to demonstrate a real fix, so that the report's "after" numbers reflect actual remediation, not just a different starting state.

**How it works:**
1. Trigger: manual code change, committed and pushed after the initial failing run is documented.
2. Logic: the hardcoded `API_KEY` is removed from source and replaced with a reference to an environment variable / GitHub Actions secret; the duplicated validation logic in `/add` and `/delete` is extracted into one shared `validate_note_input()` helper.
3. Result: re-running the pipeline shows the `code-quality` job passing its Quality Gate.

**Inputs:** The flagged SonarCloud findings from Feature 8/9.

**Outputs:** Updated `app.py`; passing Quality Gate on the next run.

**Edge cases & error handling:** Not applicable.

**Dependencies:** Features 5, 6, 8, 9.

---

## 13. Image-layer remediation
**Category:** Security fix
**Phase:** Phase 4
**Priority:** Must-have

**What it does:**
Replaces the vulnerable base image with a patched, minimal one so the Trivy gate passes.

**User story:**
As Siddhant, I want to show a real before/after CVE count, so that the report's image-layer results are credible.

**How it works:**
1. Trigger: manual Dockerfile change, committed and pushed after the initial failing Trivy run is documented.
2. Logic: `FROM python:3.8` is changed to `FROM python:3.12-slim`.
3. Result: re-running the pipeline shows the `build-and-scan` job's Trivy step passing with zero HIGH/CRITICAL CVEs.

**Inputs:** The Trivy findings from Feature 11.

**Outputs:** Updated Dockerfile; passing Trivy scan on the next run.

**Edge cases & error handling:** Not applicable.

**Dependencies:** Features 7, 10, 11.

---

## 14. Publish to Docker Hub
**Category:** CI/CD
**Phase:** Phase 4
**Priority:** Must-have

**What it does:**
Pushes the final, clean image to Docker Hub once both gates have passed.

**User story:**
As an evaluator, I want to see the pipeline complete with a real published artifact, so that I can confirm the whole flow works end-to-end, not just the scanning stages.

**How it works:**
1. Trigger: the `publish` job starts once `build-and-scan` succeeds (`needs: build-and-scan`).
2. Logic: logs into Docker Hub using `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets, rebuilds the image tagged with the Docker Hub username, and pushes it.
3. Result: the image appears in the configured Docker Hub repository.

**Inputs:** Docker Hub credentials (GitHub Actions secrets), the validated Dockerfile/source.

**Outputs:** Published image on Docker Hub.

**Edge cases & error handling:**
- Error case: invalid Docker Hub credentials → job fails at the login step, distinct from a scan failure.

**Dependencies:** Features 12, 13 (both remediations must be complete for this to represent a genuinely clean image).

---

## 15. Finding extraction for the agent
**Category:** CI/CD Automation
**Phase:** Phase 5
**Priority:** Must-have

**What it does:**
When `code-quality` or `build-and-scan` fails, this step pulls the specific finding (a SonarCloud issue or a Trivy CVE entry) out of that job's output in a structured form the agent can act on.

**User story:**
As Siddhant, I want the agent to work from a specific, structured finding rather than a raw log dump, so that its proposed fix stays scoped and predictable.

**How it works:**
1. Trigger: the `remediate` job runs when `code-quality` or `build-and-scan` reports failure.
2. Logic: queries the SonarCloud issues API for the failing project, or reads the Trivy JSON output artifact from the prior job, and extracts one representative finding (file, line, rule/CVE id, description).
3. Result: a small, structured finding object is passed to the next step (Nemotron-based fix generation).

**Inputs:** SonarCloud issues API response, or Trivy JSON scan output.

**Outputs:** A single structured finding object (file path, issue description, rule/CVE id).

**Edge cases & error handling:**
- Edge case: multiple findings present → the demo scope handles one representative finding per run rather than batching all of them, to keep the proposed diff reviewable.

**Dependencies:** Features 9 and 11 (a failed Quality Gate or Trivy scan must exist to extract from).

---

## 16. Nemotron-based fix generation
**Category:** CI/CD Automation
**Phase:** Phase 5
**Priority:** Must-have

**What it does:**
Sends the extracted finding to a Nemotron model via the NVIDIA NIM API and receives back a proposed code fix (a diff) plus a short explanation.

**User story:**
As a developer, I want the agent to propose an actual fix rather than just re-describing the problem, so that reviewing it is faster than fixing it from scratch myself.

**How it works:**
1. Trigger: runs immediately after Feature 15 within the `remediate` job.
2. Logic: sends a scoped prompt (the finding plus the relevant file's current content) to `https://integrate.api.nvidia.com/v1/chat/completions` using the `nvidia/llama-3.1-nemotron-70b-instruct` model (or a comparable Nemotron variant) and the `NVIDIA_API_KEY` secret, asking for a minimal unified diff and a one-paragraph explanation.
3. Result: a proposed diff and explanation are returned and passed to the PR-creation step.

**Inputs:** The structured finding from Feature 15; the relevant source/Dockerfile content; `NVIDIA_API_KEY`.

**Outputs:** A proposed diff (patch) and a plain-language explanation string.

**Edge cases & error handling:**
- Error case: API call fails (rate limit, invalid key) → the `remediate` job fails cleanly rather than opening an empty or broken PR.
- Edge case: the model proposes a fix that doesn't fully resolve the finding → not auto-detected at this stage; caught during human review (Feature 18), and noted honestly in the report if it happens.

**Dependencies:** Feature 15; a valid `NVIDIA_API_KEY`.

---

## 17. Agent pull request creation
**Category:** CI/CD Automation
**Phase:** Phase 5
**Priority:** Must-have

**What it does:**
Applies the proposed diff to a new branch and opens a pull request containing the change and its explanation, rather than committing to `main` directly.

**User story:**
As a course evaluator, I want to see the agent's fix arrive as a reviewable PR, so that I can confirm the automation follows a responsible, human-reviewed pattern.

**How it works:**
1. Trigger: runs immediately after Feature 16 within the `remediate` job.
2. Logic: applies the returned diff to a new branch (e.g. `agent-fix/<finding-id>`) and uses `peter-evans/create-pull-request` to open a PR against `main`, using the Nemotron-generated explanation as the PR description.
3. Result: a new pull request appears in the repository, containing the diff and explanation, awaiting review.

**Inputs:** The diff and explanation from Feature 16.

**Outputs:** An open GitHub pull request.

**Edge cases & error handling:**
- Edge case: the diff fails to apply cleanly (e.g. file changed since the finding was captured) → the job fails at this step rather than opening a broken PR.

**Dependencies:** Feature 16.

---

## 18. Human review boundary enforcement
**Category:** CI/CD Automation
**Phase:** Phase 5
**Priority:** Must-have

**What it does:**
Ensures the agent's workflow permissions and job configuration make it structurally impossible for the agent to merge its own PR or push to `main` directly — this isn't just a convention, it's enforced by what the workflow is allowed to do.

**User story:**
As a course evaluator, I want to confirm the "human-in-the-loop" claim is actually enforced, not just described in the report, so that the automation is genuinely responsible rather than only appearing to be.

**How it works:**
1. Trigger: applies to the `remediate` job's configuration at all times, not a runtime event.
2. Logic: the job's GitHub token permissions are scoped to `pull-requests: write` and `contents: write` on a feature branch only — with no permission to push to or merge `main` directly, and no auto-merge step configured anywhere in the workflow.
3. Result: the only possible outcome of the `remediate` job is an open PR; merging always requires a separate, manual developer action.

**Inputs:** Workflow permission configuration (`permissions:` block in `pipeline.yml`).

**Outputs:** N/A — this is a constraint on the system rather than a data-producing feature.

**Edge cases & error handling:** Not applicable — this is a hard boundary, not a conditional behavior.

**Dependencies:** Feature 17 (the PR creation step must respect these permission boundaries).

---

## 19. Repeatable demo reset tooling
**Category:** Demo Tooling
**Phase:** Phase 5
**Priority:** Must-have

**What it does:**
Lets any of the four demo states (fully vulnerable, fully fixed, secret-only, image-only) be restored with a single command, so the pipeline can be shown failing or passing repeatedly — for grading, a viva, or rehearsal — without manually re-editing files each time.

**User story:**
As Siddhant, I want a one-command way to reset or reintroduce the seeded issues, so that I can demo the pipeline as many times as needed without risk of forgetting to revert a manual edit correctly.

**How it works:**
1. Trigger: Siddhant runs `./scripts/reset-demo.sh <state>` from the repo root before or during a demo.
2. Logic: the script copies the matching `app.py` and `Dockerfile` from `demo-states/<state>/` over the live files, commits (skipping if nothing changed), and pushes to `main`, which triggers a fresh pipeline run.
3. Result: the repo is in exactly the intended state (all issues present, all fixed, or one isolated issue for an agent demo), and the pipeline reacts accordingly on the next run.

**Inputs:** A state name (`vulnerable`, `fixed`, `agent-secret-only`, `agent-image-only`); the corresponding pre-written files under `demo-states/`.

**Outputs:** Updated `app.py`/`Dockerfile` on `main`; a new pipeline run triggered by the push.

**Edge cases & error handling:**
- Edge case: an invalid state name is passed → the script prints valid usage and exits without making any change.
- Edge case: the requested state matches what's already live → the script detects no diff and exits without an empty commit.

**Dependencies:** Features 5, 6, 7 (the seeded issues these states restore), and Features 15–17 (the agent-focused states exist specifically to give the `remediate` job one isolated finding).

---

## Deferred / Future Features
- SARIF report upload to GitHub's Security tab — deferred since it adds setup complexity beyond what the mini-project's grading criteria require.
- Persistent (database-backed) note storage — deferred since it's irrelevant to the pipeline being evaluated.
- Extending the agent to batch-handle multiple findings per run — deferred in favor of one clear, reviewable finding per demo run.
