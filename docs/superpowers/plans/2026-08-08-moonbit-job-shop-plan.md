# moonbitJobShop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a reusable MoonBit job-shop scheduling library with models, heuristic solving, metrics, documentation, CI, and two authenticated remotes.

**Architecture:** Keep public manufacturing types in the root package, isolate scheduling and metrics into focused packages, and expose a small solver interface so later search algorithms can be added without changing the model. Use deterministic earliest-feasible dispatching for the initial solver.

**Tech Stack:** MoonBit 0.10.4, Moon toolchain, GitHub Actions, Git, GitHub CLI, GitLink remote.

---

### Task 1: Repository metadata and public domain model

**Files:** `moon.mod`, `moon.pkg`, `src/model/*.mbt`, `src/model/*_test.mbt`

- [ ] Add module metadata and public types for `Job`, `Operation`, `Machine`, `Route`, `SetupTime`, and `ScheduleInput`.
- [ ] Add failing tests for invalid durations, missing machines, and valid alternative routes.
- [ ] Run `moon test` and observe the expected missing-type failures.
- [ ] Implement validation and rerun tests.
- [ ] Commit as `feat: add job shop domain model`.

### Task 2: Deterministic heuristic scheduler

**Files:** `src/schedule/*.mbt`, `src/schedule/*_test.mbt`, `src/solver/*.mbt`

- [ ] Add tests for precedence, machine non-overlap, setup time, and alternative-machine selection.
- [ ] Implement earliest-feasible dispatching and a `Solver` interface.
- [ ] Run targeted tests, then the full test suite.
- [ ] Commit as `feat: add deterministic dispatch solver`.

### Task 3: Objectives and reporting

**Files:** `src/objective/*.mbt`, `src/report/*.mbt`, tests

- [ ] Add tests for makespan, tardiness, load balance, utilization, and Gantt events.
- [ ] Implement metric functions and stable report records.
- [ ] Run tests and commit as `feat: add scheduling objectives and reports`.

### Task 4: Example, README, and license

**Files:** `cmd/demo/main.mbt`, `cmd/demo/moon.pkg`, `examples/basic.mbt.md`, `README.md`, `LICENSE`, `CHANGELOG.md`

- [ ] Add a runnable example showing fixed and alternative routes.
- [ ] Document API, quickstart, design boundary, MoonCakes search notes, source provenance, roadmap, and contribution rules.
- [ ] Add MIT License and changelog.
- [ ] Run the example and commit as `docs: add usage guide and project metadata`.

### Task 5: CI and strict local validation

**Files:** `.github/workflows/check.yml`, `.github/workflows/test.yml`, `.github/ISSUE_TEMPLATE/bug_report.md`

- [ ] Add current MoonBit installer workflow with formatting, deny-warn check, deny-warn info, tests, native tests, and CLI example validation.
- [ ] Run `moon fmt --deny-warn`, `moon info --deny-warn`, `moon check --deny-warn`, `moon test --deny-warn`, native tests, and CLI checks locally.
- [ ] Commit as `ci: add strict MoonBit quality gates`.

### Task 6: Final audit and remotes

- [ ] Create at least 12 meaningful commits, all with the authenticated author identity.
- [ ] Confirm `git log`, source file count/scale, default branch, README/license, and no generated or virtual contributors.
- [ ] Create and push GitHub using `gh auth` and GitLink using the user-provided account authentication without writing credentials to disk.
- [ ] Add exactly one-page Chinese proposal `moonbitJobShop-项目申报书.md` and commit as `docs: add hackathon proposal`.
- [ ] Re-run all gates and record final URLs and audit summary.
