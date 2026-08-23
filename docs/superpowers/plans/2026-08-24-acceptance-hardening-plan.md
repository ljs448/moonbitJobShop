# moonbitJobShop Acceptance Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a production-shaped MoonBit job-shop scheduling library with real search, dynamic rescheduling, Pareto analysis, reproducible benchmarks, tests, CI, and package metadata suitable for August Hackathon acceptance.

**Architecture:** Keep public domain types and stable functions in the existing `src` root package. Split implementation into focused `.mbt` files by responsibility, reusing the deterministic dispatch core through explicit strategy and evaluation records. Keep the benchmark executable separate from the library and generate its checked-in report from a real local run.

**Tech Stack:** MoonBit stable toolchain, standard library only, GitHub Actions, GitHub CLI, Mooncakes CLI.

---

### Task 1: Establish red tests and package identity

**Files:** `src/*_test.mbt`, `moon.mod`, `cmd/demo/moon.pkg`

- [ ] Add tests for priority dispatch, interval calendars, search budgets, dynamic events, Pareto dominance, and stable output before adding implementations.
- [ ] Run `moon test` and confirm the new symbols fail because the behavior is not implemented.
- [ ] Change the module namespace and imports from the old placeholder owner to `ljs448/moonbitJobShop`, preserving the GitHub repository URL.
- [ ] Re-run the baseline tests after only the metadata change.

### Task 2: Complete the domain and scheduling kernel

**Files:** `src/calendar.mbt`, `src/priority.mbt`, `src/dispatch_options.mbt`, `src/schedule_utils.mbt`, `src/validation_extra.mbt`

- [ ] Implement half-open interval utilities, machine calendars, order priorities, dispatch options, stable job ordering, and schedule validation.
- [ ] Add deterministic priority dispatch with FIFO, shortest-processing-time, earliest-due-date, least-slack, and setup-aware rules.
- [ ] Run targeted tests and then `moon check` and `moon test`.

### Task 3: Add real improvement algorithms

**Files:** `src/search_*.mbt`, `src/evaluation_*.mbt`, `src/random.mbt`

- [ ] Implement objective configuration, candidate evaluation, swap/insert/reverse neighborhoods, local search, simulated annealing, tabu search, and a deterministic genetic search.
- [ ] Ensure zero budgets return the baseline, seeds reproduce identical checksums, and every returned schedule is feasible.
- [ ] Add regression tests for monotonic best-so-far behavior and small known fixtures.

### Task 4: Add dynamic scheduling and multi-objective analysis

**Files:** `src/dynamic_*.mbt`, `src/pareto_*.mbt`, `src/critical_path.mbt`, `src/bottleneck.mbt`

- [ ] Implement order insert/cancel, machine outage intervals, frozen prefixes, rolling-horizon rescheduling, event logs, critical path, bottleneck ranking, and weighted objectives.
- [ ] Implement objective vectors, dominance, Pareto frontier, crowding-style diversity, and deterministic compromise selection.
- [ ] Expand edge tests around touching intervals, duplicate events, empty frontiers, and infeasible changes.

### Task 5: Add applied output and benchmark evidence

**Files:** `src/format_*.mbt`, `src/benchmark_*.mbt`, `cmd/benchmark/*`, `examples/*`, `docs/benchmark.md`

- [ ] Add CSV and ASCII Gantt output, summary/signature helpers, and a fixed benchmark data generator.
- [ ] Add a benchmark CLI that prints actual workload size, solution metrics, checksum, and timing-friendly markers.
- [ ] Run the CLI repeatedly, record the observed result and environment in `docs/benchmark.md`, and verify the report matches the source output.

### Task 6: Hardening, documentation, and CI

**Files:** `README.md`, `.github/workflows/check.yml`, `.github/workflows/test.yml`, `CHANGELOG.md`, `.gitignore`

- [ ] Rewrite README around project positioning, capabilities, quick start, CLI, architecture, benchmark, tests, CI, and MIT license; remove internal application wording.
- [ ] Consolidate CI around the official MoonBit matrix pattern with stable installer, all stable targets, coverage, native tests, format/API diff, and demo/benchmark checks.
- [ ] Verify build artifacts and generated interfaces stay ignored and update the changelog with user-facing releases.

### Task 7: Final verification, commit, merge, publish, and audit

**Files:** repository history and generated package metadata only

- [ ] Run `moon fmt --check`, `moon check --deny-warn --target all`, `moon test --deny-warn --target all`, `moon info`, CLI checks, and source-count commands.
- [ ] Inspect `git diff`, commit history, default branch, GitHub owner, license, and proposal checksum without modifying the proposal.
- [ ] Create meaningful commits on the isolated branch, merge into `main`, push only the GitHub remote, and publish the module to Mooncakes using the existing login.
- [ ] Re-query GitHub and Mooncakes, run the self-review checklist, and report facts, inferences, and remaining risks separately.
