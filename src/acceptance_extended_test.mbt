///|
test "dashboard extensions expose workload bands and stable KPI output" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let bands = schedule_load_bands(schedule, input.machines)
  assert_eq(bands.length(), input.machines.length())
  assert_true(schedule_histogram(schedule, 4).length() > 0)
  assert_true(late_job_ids(schedule, input.jobs).length() >= 0)
  assert_true(
    dashboard_kpi_csv(schedule, input.jobs, input.machines).contains("makespan"),
  )
  assert_true(resource_balance_score(schedule, input.machines) >= 0)
}

///|
test "lookahead ranking is deterministic and route alternatives are bounded" {
  let input = acceptance_fixture()
  let ranked = rank_operations(input, DispatchOptions::default(), 3)
  assert_true(ranked.length() > 0)
  assert_true(ranked.length() <= 3)
  assert_true(lookahead_schedule(input, DispatchOptions::default(), 2) is Ok(_))
  let alternatives = route_alternatives(input.jobs[0].operations[0])
  assert_true(alternatives.length() >= 1)
  assert_true(route_width_histogram(input).length() > 0)
  assert_true(select_fastest_route(input.jobs[0].operations[0]) is Some(_))
}

///|
test "constraint policies separate hard and soft due-date rules" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let normal = validate_with_policy(
    schedule,
    input,
    ConstraintPolicy::default(),
    [],
  )
  assert_true(normal.is_feasible())
  let strict = validate_with_policy(
    schedule,
    input,
    ConstraintPolicy::strict_due_dates(),
    [],
  )
  assert_true(strict.hard_violation_count() >= normal.hard_violation_count())
  assert_true(constraint_counts(strict).contains("hard="))
}

///|
test "search portfolio returns a reproducible best candidate" {
  let input = acceptance_fixture()
  let portfolio = SearchPortfolio::small(seed=7)
  let first = search_portfolio(input, DispatchOptions::default(), portfolio).unwrap()
  let second = search_portfolio(input, DispatchOptions::default(), portfolio).unwrap()
  assert_eq(first.best.schedule.signature(), second.best.schedule.signature())
  assert_true(first.traces.length() >= 2)
  assert_true(first.summary().contains("algorithms="))
}

///|
test "capacity projections and benchmark datasets remain deterministic" {
  let input = acceptance_fixture()
  let outage = MachineCalendar::new(machine_id="mill")
    .add_unavailable(Interval::new(start=3, end=7))
    .unwrap()
  let projection = project_capacity(input, [outage], horizon=20)
  assert_true(projection.total_capacity > 0)
  assert_true(projection.blocked_capacity >= 4)
  assert_true(capacity_table(projection).contains("mill"))
  let dataset = benchmark_dataset()
  assert_true(dataset.cases.length() >= 3)
  assert_true(
    dataset.manifest().split("\n").length() >= dataset.cases.length() + 1,
  )
}

///|
test "dynamic report renderers include all operational sections" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let versions = replay_events(
    input,
    [
      [ScheduleEvent::cancel("rush")],
      [ScheduleEvent::machine_outage("mill", 3, 7)],
    ],
    RescheduleOptions::default(),
  ).unwrap()
  let report = render_operational_report(schedule, input, versions, [])
  assert_true(report.contains("schedule"))
  assert_true(report.contains("capacity"))
  assert_true(report.contains("constraints"))
  assert_true(report.contains("versions"))
}

///|
test "setup analysis and strict input diagnostics expose explainable signals" {
  let input = acceptance_fixture()
  assert_true(setup_transition_matrix(input).length() > 0)
  assert_true(setup_group_loads(input).length() > 0)
  assert_true(setup_cost_for_order(input, input.jobs) >= 0)
  assert_true(setup_summary(input).contains("transitions="))
  let diagnostics = input_diagnostics(input)
  assert_eq(diagnostics.jobs, 3)
  assert_eq(diagnostics.operations, 8)
  assert_true(diagnostics_summary(diagnostics).contains("operations=8"))
  assert_true(strict_input_check(input) is Ok(_))
}

///|
test "trace export and policy matrix preserve deterministic schedule identity" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let trace = schedule_trace(schedule)
  assert_eq(trace.length(), schedule.operation_count())
  assert_true(trace_csv(trace).contains("operation"))
  assert_true(trace_checksum(trace) != "")
  let results = dispatch_policy_matrix(input).unwrap()
  assert_true(results.length() >= 3)
  assert_true(policy_quality_table(results).contains("policy"))
  assert_true(best_policy_name(results) != "")
}

///|
test "search diagnostics report convergence without changing the result" {
  let input = acceptance_fixture()
  let result = local_search(
    input,
    DispatchOptions::default(),
    SearchConfig::new(iterations=3, seed=4),
  ).unwrap()
  let diagnostic = search_diagnostic("local", result)
  assert_true(diagnostic.iterations == 3)
  assert_true(search_diagnostic_text(diagnostic).contains("local"))
  assert_true(history_is_nonincreasing(result.history))
}

///|
test "horizon slices and sensitivity reports cover operational what-if analysis" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let windows = schedule_windows(schedule, width=4)
  assert_true(windows.length() > 0)
  assert_true(horizon_table(windows).contains("start"))
  let sensitivity = dispatch_sensitivity(input, [0, 2, 4]).unwrap()
  assert_eq(sensitivity.points.length(), 3)
  assert_true(sensitivity_summary(sensitivity).contains("points=3"))
  assert_true(sensitivity_table(sensitivity).contains("frozen_until"))
}

///|
test "operational ledger is complete and internally consistent" {
  let input = acceptance_fixture()
  let schedule = dispatch(input).unwrap()
  let ledger = build_ledger(schedule)
  assert_true(ledger_matches_schedule(ledger, schedule))
  assert_eq(ledger.entry_count(), input.operation_count())
  assert_true(ledger_machine_table(ledger).contains("machine"))
  assert_true(ledger_checksum(ledger) != "")
}
