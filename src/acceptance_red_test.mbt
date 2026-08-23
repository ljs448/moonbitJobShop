///|
fn acceptance_fixture() -> ScheduleInput {
  let machines = [
    Machine::new(id="cut", name="Cutter"),
    Machine::new(id="mill", name="Mill"),
    Machine::new(id="inspect", name="Inspection"),
  ]
  let jobs = [
    Job::new(id="steel-1", name="Steel bracket", due_time=14, operations=[
      Operation::new(
        id="steel-cut",
        name="Cut",
        duration=4,
        machine_ids=["cut", "mill"],
        setup_group="steel",
      ),
      Operation::new(
        id="steel-finish",
        name="Finish",
        duration=3,
        machine_ids=["mill"],
        setup_group="steel",
      ),
      Operation::new(
        id="steel-check",
        name="Inspect",
        duration=2,
        machine_ids=["inspect"],
        setup_group="general",
      ),
    ]),
    Job::new(id="alu-1", name="Aluminum plate", due_time=11, operations=[
      Operation::new(
        id="alu-cut",
        name="Cut",
        duration=2,
        machine_ids=["cut", "mill"],
        setup_group="aluminum",
      ),
      Operation::new(
        id="alu-drill",
        name="Drill",
        duration=5,
        machine_ids=["mill"],
        setup_group="aluminum",
      ),
      Operation::new(
        id="alu-check",
        name="Inspect",
        duration=1,
        machine_ids=["inspect"],
        setup_group="general",
      ),
    ]),
    Job::new(id="rush", name="Rush order", due_time=8, operations=[
      Operation::new(
        id="rush-cut",
        name="Cut",
        duration=1,
        machine_ids=["cut"],
        setup_group="rush",
      ),
      Operation::new(
        id="rush-check",
        name="Inspect",
        duration=1,
        machine_ids=["inspect"],
        setup_group="general",
      ),
    ]),
  ]
  ScheduleInput::new(
    jobs~,
    machines~,
    setup_times=[
      SetupTime::new(from_group="steel", to_group="aluminum", duration=2),
      SetupTime::new(from_group="aluminum", to_group="steel", duration=3),
      SetupTime::new(from_group="rush", to_group="steel", duration=1),
      SetupTime::new(from_group="steel", to_group="rush", duration=1),
    ],
  )
}

///|
test "dispatch options respect a machine calendar and rule" {
  let calendar = MachineCalendar::new(machine_id="cut")
  let blocked = calendar.add_unavailable(Interval::new(start=0, end=3))
  assert_eq(blocked, None)
  let options = DispatchOptions::default()
    .with_rule(DispatchRule::EarliestDueDate)
    .with_calendar(calendar)
  match dispatch_with_options(acceptance_fixture(), options) {
    Ok(schedule) => {
      assert_true(schedule.operations.length() == 8)
      assert_true(schedule.operations[0].start >= 3)
      assert_eq(validate_schedule(schedule, acceptance_fixture()), None)
    }
    Err(message) => fail(message)
  }
}

///|
test "interval boundaries are half open and calendars find the next slot" {
  let first = Interval::new(start=0, end=4)
  let touching = Interval::new(start=4, end=7)
  let overlapping = Interval::new(start=3, end=5)
  assert_true(!first.overlaps(touching))
  assert_true(first.overlaps(overlapping))
  assert_true(first.contains(0))
  assert_true(!first.contains(4))
  let calendar = MachineCalendar::new(machine_id="m")
  assert_eq(calendar.add_unavailable(Interval::new(start=4, end=6)), None)
  assert_eq(calendar.next_available(3, 2), 3)
  assert_eq(calendar.next_available(4, 2), 6)
}

///|
test "schedule utilities identify overlap and stable ordering" {
  let operations = [
    ScheduledOperation::new(
      job_id="b", operation_id="b1", machine_id="m", setup_group="g",
      start=2, end=5,
    ),
    ScheduledOperation::new(
      job_id="a", operation_id="a1", machine_id="m", setup_group="g",
      start=0, end=2,
    ),
  ]
  let schedule = Schedule::new(operations~)
  assert_eq(schedule.machine_intervals("m").length(), 2)
  assert_eq(schedule.signature(), "a:a1@m:0-2|b:b1@m:2-5")
  assert_true(validate_schedule(schedule, acceptance_fixture()) is Some(_))
}

///|
test "local search is deterministic and never returns an infeasible schedule" {
  let options = DispatchOptions::default().with_rule(DispatchRule::Fifo)
  let config = SearchConfig::new(iterations=18, seed=41)
  let first = local_search(acceptance_fixture(), options, config)
  let second = local_search(acceptance_fixture(), options, config)
  match (first, second) {
    (Ok(left), Ok(right)) => {
      assert_eq(left.checksum, right.checksum)
      assert_true(left.evaluation.score <= left.baseline.score)
      assert_eq(validate_schedule(left.schedule, acceptance_fixture()), None)
      assert_true(left.history.length() > 0)
    }
    (Err(message), _) => fail(message)
    (_, Err(message)) => fail(message)
  }
}

///|
test "tabu and genetic searches honor zero budget and seed" {
  let options = DispatchOptions::default()
  let zero = SearchConfig::new(iterations=0, seed=5)
  match tabu_search(acceptance_fixture(), options, zero) {
    Ok(result) => assert_eq(result.schedule.signature(), result.baseline.schedule.signature())
    Err(message) => fail(message)
  }
  let config = SearchConfig::new(iterations=8, seed=9).with_population_size(5)
  match genetic_search(acceptance_fixture(), options, config) {
    Ok(result) => {
      assert_true(result.population_history.length() > 0)
      assert_eq(validate_schedule(result.schedule, acceptance_fixture()), None)
    }
    Err(message) => fail(message)
  }
}

///|
test "dynamic rescheduling applies insert cancel and outage events" {
  let extra = Job::new(id="new", name="New order", due_time=30, operations=[
    Operation::new(
      id="new-cut", name="Cut", duration=2, machine_ids=["cut"], setup_group="new",
    ),
  ])
  let events = [
    ScheduleEvent::Insert(job=extra),
    ScheduleEvent::Cancel(job_id="rush"),
    ScheduleEvent::MachineOutage(machine_id="mill", start=2, end=5),
  ]
  let result = reschedule(
    acceptance_fixture(),
    events,
    RescheduleOptions::default().with_frozen_until(1),
  )
  match result {
    Ok(outcome) => {
      assert_eq(outcome.applied_events, 3)
      assert_true(outcome.cancelled_jobs.contains("rush"))
      assert_true(outcome.schedule.operations.length() >= 7)
      assert_eq(validate_schedule(outcome.schedule, outcome.input), None)
    }
    Err(message) => fail(message)
  }
}

///|
test "pareto frontier removes dominated schedules and chooses a compromise" {
  let baseline = Schedule::new(operations=[
    ScheduledOperation::new(
      job_id="j", operation_id="o", machine_id="m", setup_group="g", start=0, end=10,
    ),
  ])
  let fast = Schedule::new(operations=[
    ScheduledOperation::new(
      job_id="j", operation_id="o", machine_id="m", setup_group="g", start=0, end=8,
    ),
  ])
  let smooth = Schedule::new(operations=[
    ScheduledOperation::new(
      job_id="j", operation_id="o", machine_id="m", setup_group="g", start=0, end=9,
    ),
  ])
  let points = [
    ParetoPoint::new(schedule=baseline, objectives=ObjectiveVector::new(
      makespan=10, tardiness=4, load_balance=1, setup_count=3,
    )),
    ParetoPoint::new(schedule=fast, objectives=ObjectiveVector::new(
      makespan=8, tardiness=7, load_balance=4, setup_count=5,
    )),
    ParetoPoint::new(schedule=smooth, objectives=ObjectiveVector::new(
      makespan=9, tardiness=3, load_balance=2, setup_count=2,
    )),
  ]
  let frontier = pareto_frontier(points)
  assert_eq(frontier.length(), 2)
  assert_true(frontier[0].objectives.dominates(frontier[1].objectives) == false)
  let chosen = choose_compromise(frontier, ObjectiveWeights::balanced())
  assert_true(chosen is Some(_))
}

///|
test "analysis and output expose applied scheduling evidence" {
  let input = acceptance_fixture()
  match dispatch(input) {
    Ok(schedule) => {
      let critical = critical_path(schedule)
      let bottlenecks = bottleneck_ranking(schedule, input.machines)
      assert_true(critical.length() > 0)
      assert_true(bottlenecks.length() == input.machines.length())
      assert_true(schedule.to_csv().contains("job_id,operation_id"))
      assert_true(schedule.ascii_gantt(input.machines, width=48).contains("cut"))
      assert_true(schedule.summary(input.jobs).contains("makespan"))
    }
    Err(message) => fail(message)
  }
}

///|
test "benchmark generator is deterministic and has useful scale" {
  let case_a = benchmark_case(jobs=12, machines=4, operations_per_job=5)
  let case_b = benchmark_case(jobs=12, machines=4, operations_per_job=5)
  assert_eq(case_a.signature, case_b.signature)
  assert_eq(case_a.input.jobs.length(), 12)
  assert_eq(case_a.operation_count, 60)
  match run_benchmark(case_a, repeats=2) {
    Ok(summary) => {
      assert_true(summary.schedule.operations.length() == 60)
      assert_true(summary.checksum != "")
      assert_true(summary.repeats == 2)
    }
    Err(message) => fail(message)
  }
}

///|
test "validation rejects duplicate identifiers and invalid search parameters" {
  let machine = Machine::new(id="m", name="Machine")
  let operation = Operation::new(
    id="o", name="Operation", duration=1, machine_ids=["m"], setup_group="g",
  )
  let duplicate = ScheduleInput::new(
    jobs=[
      Job::new(id="j", name="One", due_time=2, operations=[operation]),
      Job::new(id="j", name="Two", due_time=2, operations=[operation]),
    ],
    machines=[machine],
    setup_times=[],
  )
  assert_true(duplicate.validate() is Some(_))
  assert_true(SearchConfig::new(iterations=-1, seed=1).validate() is Some(_))
  assert_true(Interval::try_new(start=4, end=3) is Err(_))
}
