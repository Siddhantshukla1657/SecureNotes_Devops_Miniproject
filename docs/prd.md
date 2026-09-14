# SecureNotes Secure CI Pipeline — Product Requirements Document

> **Status:** Draft | **Last updated:** September 14, 2026 | **Owner:** Siddhant Shukla

## 1. Overview
SecureNotes is a small, UI-driven notes app that exists to demonstrate a layered DevSecOps pipeline. The pipeline scans source code with SonarQube (or SonarCloud) and container images with Trivy before anything is published to Docker Hub, showing "shift-left security" in a way that's visible on screen rather than buried in logs. On top of the scan-and-gate flow, the pipeline includes an automated remediation agent (powered by NVIDIA's Nemotron model via the NIM API) that reads failed scan findings, proposes a fix, and opens a pull request for a human to review — rather than pushing straight to main. It's built for a Lab CA mini-project submission where the pipeline — not the app — is what's being evaluated.

## 2. Problem Statement
Teams that containerize and ship applications frequently often have no automated gate for two separate categories of risk: code-level issues (bugs, code smells, hardcoded secrets) that live in the source, and image-level issues (outdated base images, known CVEs) that only appear after the app is built into a container. Without automated checks, both categories routinely reach production because catching them depends on someone manually remembering to look. Even once caught, someone still has to manually diagnose and fix each finding, which slows down remediation. This project builds a small, realistic demonstration of catching both categories automatically on every commit, and of an agent proposing the fix itself — with a human still reviewing before anything merges.

## 3. Goals
- Demonstrate an automated, two-layer security gate (code + image) that blocks a pipeline on real, not staged, findings.
- Produce a working, presentable demo app so the "before/after" story is visible in a browser, not just in terminal output.
- Show a complete remediation story: real issues introduced, real tool output flagging them, real fixes, and a clean final run.
- Demonstrate an automated remediation agent that reads a failed scan's findings, generates a proposed fix using Nemotron (via the NVIDIA NIM API), and opens a pull request for developer review rather than committing directly.
- Keep the entire pipeline free to run and easy to reproduce for evaluation.

## 4. Non-Goals
- SecureNotes is not meant to be a production-grade note-taking app — no persistent database, no multi-user auth, no offline support.
- This project does not attempt to cover every SonarQube or Trivy rule category — only enough to produce a clear, gradeable before/after result.
- No attempt to demonstrate horizontal scaling, load testing, or production traffic handling.
- The remediation agent is not permitted to merge or push directly to `main` under any circumstance — it only ever proposes changes via a pull request. Autonomous merging is explicitly out of scope.

## 5. Target Users / Personas
| Persona | Description | Primary need |
|---|---|---|
| Course evaluator | Grades the Lab CA submission against the syllabus's DevSecOps/shift-left security expectations | A pipeline that visibly fails on real issues, visibly passes after remediation, and shows responsible human-in-the-loop automation |
| Siddhant (project owner) | Final-year student building and presenting the project | A reproducible, demo-ready pipeline that isn't fragile during a live walkthrough |
| Developer (reviewer role) | Whoever reviews the agent's proposed PR — played by Siddhant during the demo | A clear, reviewable diff and explanation before approving any automated fix |

## 6. User Stories
- As a course evaluator, I want to see the pipeline fail at the code-scan stage on a real hardcoded secret, so that I know the gate isn't just theoretical.
- As a course evaluator, I want to see the same pipeline pass end-to-end after remediation, so that I can confirm the fixes were real and effective.
- As Siddhant, I want a working browser UI for the demo app, so that the presentation shows a real product being protected, not just raw API calls.
- As Siddhant, I want the pipeline stages clearly separated (code scan → build → image scan → publish), so that I can explain each gate independently during a viva.
- As a developer, I want the remediation agent to open a pull request with a proposed fix and a plain-language explanation, so that I can review and approve it instead of trusting an automated change blindly.
- As a course evaluator, I want to see that the agent cannot merge its own PR, so that I can confirm the automation follows a responsible human-in-the-loop pattern.

## 7. Requirements

### 7.1 Functional Requirements
1. The system must provide a browser-based UI for adding, viewing, and deleting notes.
2. The system must expose a `/health` endpoint that confirms the running container is serving traffic.
3. The system must run a SonarQube (or SonarCloud) scan on every push and fail the pipeline if the Quality Gate does not pass.
4. The system must build a Docker image only after the code-scan stage passes.
5. The system must run a Trivy scan on the built image and fail the pipeline if HIGH or CRITICAL severity CVEs are found.
6. The system must push the final image to Docker Hub only after both gates pass.
7. The system must intentionally contain, in its initial state, one hardcoded secret, one instance of duplicated logic, and one outdated base image, so that both scanners have real findings to report.
8. On a code-quality or image-scan failure, the system must invoke the remediation agent, which sends the relevant finding to Nemotron (via the NVIDIA NIM API) and receives a proposed fix.
9. The remediation agent must open a pull request containing the proposed fix and a plain-language explanation of the change — it must never commit or push directly to `main`.
10. A human developer must explicitly review and merge the agent's pull request before the fix takes effect on `main`.

### 7.2 Non-Functional Requirements
- The pipeline must be fully reproducible using free-tier tools only (GitHub Actions free minutes, SonarCloud free tier, Trivy open-source, Docker Hub free tier, NVIDIA NIM free developer credits).
- Each pipeline run should complete in a few minutes, since it will likely be re-run several times during grading or a live demo.
- Secrets used by the pipeline itself (Sonar token, Docker Hub credentials, NVIDIA API key) must be stored as GitHub Actions secrets, never committed to the repository.
- The remediation agent's proposed diffs must be scoped narrowly (one finding, one file) to keep review fast and outputs predictable.
- The pipeline's failing and passing states must be reproducible on demand, since the project will be demonstrated more than once (development, rehearsal, grading).

## 8. Success Metrics
| Metric | Target | Timeframe |
|---|---|---|
| Pipeline fails on first run (pre-remediation) | Fails at code-scan stage, confirmed by screenshot/log | Before remediation |
| SonarQube findings reduced | Hardcoded secrets: 1 → 0; flagged code smells: reduced to near zero | After Remediation Round 1 |
| Trivy HIGH/CRITICAL CVEs | Reduced to 0 after base image swap | After Remediation Round 2 |
| Agent PR quality | Agent opens at least one reviewable PR with a correct or near-correct proposed fix and clear explanation | During Phase 5 demo |
| Demo repeatability | Any of the four demo states can be restored with a single command and re-run without manual file edits | Ongoing, from Phase 5 onward |
| Pipeline | Overall Status | All four core stages pass, plus at least one agent-proposed PR reviewed and merged | Final submission run |

## 9. Constraints & Assumptions
- Constraint: must use only free-tier tools (course/personal budget has no allowance for paid SonarQube, scanning, or LLM inference services).
- Constraint: GitHub-hosted runners are used; no self-hosted runner infrastructure.
- Assumption: SonarCloud (hosted) is used instead of a self-hosted SonarQube instance, since GitHub-hosted Actions runners cannot reach a scanner running on a local machine (`localhost`) — this was a hosting inconsistency in the original mini-project draft and is resolved by this assumption.
- Assumption: the demo app's in-memory data store (no database) is acceptable since data persistence is out of scope for the assignment.
- Assumption: NVIDIA's free developer-tier NIM API credits are sufficient for the handful of remediation calls made during development and the final demo.

## 10. Dependencies
- GitHub (source control + Actions runners)
- SonarCloud (hosted SonarQube-compatible scanning; free for public repos)
- Trivy (open-source, runs inside the Actions workflow)
- Docker Hub (free-tier registry for the final published image)
- NVIDIA NIM API (Nemotron model access for the remediation agent)
- `peter-evans/create-pull-request` GitHub Action (used by the agent to open PRs instead of pushing directly)
- `scripts/reset-demo.sh` + `demo-states/` (internal tooling to restore any demo state for repeated demonstrations)

## 11. Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Self-hosted SonarQube unreachable from GitHub Actions | High (if attempted) | High — blocks entire pipeline | Use SonarCloud instead of local SonarQube |
| Trivy flags a CVE with no available fix in any Python base image | Low | Medium — could block final pass | Use `python:3.12-slim`, and if needed, document an accepted CVE via `.trivyignore` with justification |
| Live demo re-run is slow or flaky during evaluation | Medium | Medium — hurts presentation | Keep the app minimal so builds/scans stay fast; pre-record a backup screen capture of a full run |
| Docker Hub free-tier rate limits during repeated testing | Low | Low | Avoid excessive repeated pushes while developing; only push on final validated runs |
| Nemotron proposes an incorrect or incomplete fix | Medium | Medium — could confuse the demo if presented as "solved" | Frame the agent step as "proposed fix for review," not "automatic fix"; keep a manual fallback ready if the PR needs correction |
| NVIDIA API key/rate limits fail during a live demo | Low | Medium — agent step fails on stage | Pre-test the agent step ahead of the demo; have a recorded fallback run of a successful agent PR |

## 12. Open Questions
- [ ] Confirm whether the evaluator wants a live demo or a recorded walkthrough — affects how much emphasis to put on making the UI presentable versus just documenting screenshots.
- [ ] Confirm whether `.trivyignore` usage (if a CVE turns out to be genuinely unfixable) needs to be explained in the final report or is out of scope.
- [ ] Decide whether the remediation agent should run automatically on every failure, or be manually triggered (e.g. `workflow_dispatch`) to control API usage during development.
