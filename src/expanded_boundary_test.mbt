///|
test "domain helpers expose work, routes and safe lookup" {
  let input = acceptance_fixture()
  assert_eq(input.operation_count(), 8)
  assert_eq(input.total_work(), 19)
  assert_eq(input.find_machine("mill").unwrap().name, "Mill")
  assert_true(input.find_machine("missing") is None)
  assert_eq(input.jobs[0].total_work(), 9)
  assert_eq(input.jobs[0].operation_index("steel-finish"), Some(1))
  assert_eq(input.jobs[0].operation_index("unknown"), None)
  assert_true(input.jobs[0].operations[0].supports_machine("cut"))
  assert_true(!input.jobs[0].operations[0].supports_machine("inspect"))
}

///|
test "calendar analytics merge gaps and calculate working capacity" {
  let base = MachineCalendar::new(machine_id="m")
  let first = match base.add_unavailable(Interval::new(start=2, end=4)) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  let calendar = match first.add_unavailable(Interval::new(start=7, end=9)) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  assert_eq(calendar.unavailable_count(), 2)
  assert_eq(calendar.blocked_time(), 4)
  assert_eq(calendar.working_time(until=10), 6)
  assert_eq(calendar.availability_gaps(until=10).length(), 3)
  assert_true(calendar.is_available(Interval::new(start=4, end=6)))
  assert_true(!calendar.is_available(Interval::new(start=3, end=5)))
}

///|
test "advanced schedule statistics describe bottlenecks and waiting" {
  let input = acceptance_fixture()
  match dispatch(input) {
    Ok(schedule) => {
      assert_true(schedule.start_time("steel-1") >= 0)
      assert_true(schedule.completion_time("steel-1") > 0)
      assert_true(
        schedule.machine_span("mill") >= schedule.machine_load("mill"),
      )
      assert_true(schedule.idle_time("mill") >= 0)
      let stats = schedule_stats(schedule, input.jobs, input.machines)
      assert_true(stats.average_flow_time > 0)
      assert_true(stats.critical_length > 0)
      assert_true(stats.total_waiting >= 0)
      assert_true(stats.utilization_percent.length() == 3)
    }
    Err(message) => fail(message)
  }
}

///|
test "neighborhood generation covers swap insert and reverse moves" {
  let jobs = acceptance_fixture().jobs
  let swaps = generate_job_neighbors(jobs, NeighborhoodKind::swap(), limit=4)
  let inserts = generate_job_neighbors(
    jobs,
    NeighborhoodKind::insert(),
    limit=4,
  )
  let reverses = generate_job_neighbors(
    jobs,
    NeighborhoodKind::reverse(),
    limit=4,
  )
  assert_true(swaps.length() > 0)
  assert_true(inserts.length() > 0)
  assert_true(reverses.length() > 0)
  assert_eq(swaps[0].length(), jobs.length())
  assert_true(job_order_signature(swaps[0]) != job_order_signature(jobs))
  assert_true(job_order_signature(inserts[0]) != job_order_signature(jobs))
  assert_true(job_order_signature(reverses[0]) != job_order_signature(jobs))
}

///|
test "annealing search is bounded and reproducible" {
  let config = AnnealingConfig::new(iterations=10, seed=13)
  let first = anneal_search(
    acceptance_fixture(),
    DispatchOptions::default(),
    config,
  )
  let second = anneal_search(
    acceptance_fixture(),
    DispatchOptions::default(),
    config,
  )
  match (first, second) {
    (Ok(left), Ok(right)) => {
      assert_eq(left.checksum, right.checksum)
      assert_true(left.history.length() >= 1)
      assert_true(left.evaluation.feasible)
    }
    (Err(message), _) => fail(message)
    (_, Err(message)) => fail(message)
  }
  assert_true(AnnealingConfig::new(iterations=-1, seed=1).validate() is Some(_))
}

///|
test "pareto archive keeps only nondominated unique points" {
  let schedule = Schedule::new(operations=[])
  let a = ParetoPoint::new(
    schedule~,
    objectives=ObjectiveVector::new(
      makespan=4,
      tardiness=2,
      load_balance=2,
      setup_count=1,
    ),
  )
  let b = ParetoPoint::new(
    schedule~,
    objectives=ObjectiveVector::new(
      makespan=5,
      tardiness=3,
      load_balance=3,
      setup_count=2,
    ),
  )
  let archive = ParetoArchive::new().add(a).add(b).add(a)
  assert_eq(archive.frontier().length(), 1)
  assert_eq(pareto_rank([a, b]), [0, 1])
  assert_true(archive.best(ObjectiveWeights::balanced()) is Some(_))
}

///|
test "rolling window rejects invalid ranges and records schedule changes" {
  let window = match RollingWindow::try_new(start=2, end=12) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  assert_eq(window.duration(), 10)
  assert_true(RollingWindow::try_new(start=4, end=4) is Err(_))
  let result = reschedule_window(
    acceptance_fixture(),
    window,
    [ScheduleEvent::cancel("rush")],
    RescheduleOptions::default(),
  )
  match result {
    Ok(value) => {
      assert_eq(value.applied_events, 1)
      assert_true(value.schedule.operation_count() < 8)
    }
    Err(message) => fail(message)
  }
}

///|
test "schedule diffs identify added removed and moved work" {
  let before = Schedule::new(operations=[
    ScheduledOperation::new(
      job_id="j",
      operation_id="o",
      machine_id="m",
      setup_group="g",
      start=0,
      end=2,
    ),
  ])
  let after = Schedule::new(operations=[
    ScheduledOperation::new(
      job_id="j",
      operation_id="o",
      machine_id="m",
      setup_group="g",
      start=2,
      end=4,
    ),
    ScheduledOperation::new(
      job_id="k",
      operation_id="k1",
      machine_id="m",
      setup_group="g",
      start=4,
      end=5,
    ),
  ])
  let diff = diff_schedules(before, after)
  assert_eq(diff.added.length(), 1)
  assert_eq(diff.removed.length(), 0)
  assert_eq(diff.moved.length(), 1)
  assert_true(diff.has_changes())
  assert_true(diff.summary().contains("added=1"))
}

///|
test "benchmark suite has named scales and stable references" {
  let suite = benchmark_suite()
  assert_true(suite.length() >= 3)
  assert_true(suite[0].name != "")
  match run_benchmark(suite[0].case, repeats=1) {
    Ok(summary) =>
      assert_true(benchmark_reference(suite[0], summary).contains("checksum"))
    Err(message) => fail(message)
  }
}

///|
test "text and table renderers remain useful for empty and nonempty data" {
  let empty = Schedule::new(operations=[])
  assert_true(schedule_to_json(empty).contains("operations"))
  assert_eq(machine_gantt_rows(empty, []).length(), 0)
  let reports = [summarize(empty, [], [])]
  assert_true(render_summary_table(reports).contains("makespan"))
  assert_true(render_schedule_text(empty).contains("operation_count=0"))
}
