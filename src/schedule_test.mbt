///|
test "dispatch preserves precedence and machine capacity" {
  let machines = [Machine::new(id="m1", name="Cutter")]
  let job = Job::new(id="j1", name="Part", due_time=20, operations=[
    Operation::new(
      id="o1",
      name="Cut",
      duration=3,
      machine_ids=["m1"],
      setup_group="steel",
    ),
    Operation::new(
      id="o2",
      name="Drill",
      duration=2,
      machine_ids=["m1"],
      setup_group="steel",
    ),
  ])
  let result = dispatch(
    ScheduleInput::new(jobs=[job], machines~, setup_times=[]),
  )
  match result {
    Ok(schedule) => {
      assert_eq(schedule.operations.length(), 2)
      assert_eq(schedule.operations[0].start, 0)
      assert_eq(schedule.operations[0].end, 3)
      assert_eq(schedule.operations[1].start, 3)
      assert_eq(schedule.makespan(), 5)
    }
    Err(message) => fail(message)
  }
}

///|
test "dispatch charges setup time and chooses the earliest alternative machine" {
  let machines = [
    Machine::new(id="m1", name="Cutter 1"),
    Machine::new(id="m2", name="Cutter 2"),
  ]
  let jobs = [
    Job::new(id="j1", name="Steel", due_time=10, operations=[
      Operation::new(
        id="o1",
        name="Cut",
        duration=4,
        machine_ids=["m1"],
        setup_group="steel",
      ),
    ]),
    Job::new(id="j2", name="Aluminum", due_time=20, operations=[
      Operation::new(
        id="o2",
        name="Cut",
        duration=2,
        machine_ids=["m1", "m2"],
        setup_group="aluminum",
      ),
    ]),
  ]
  let setups = [
    SetupTime::new(from_group="steel", to_group="aluminum", duration=3),
  ]
  match dispatch(ScheduleInput::new(jobs~, machines~, setup_times=setups)) {
    Ok(schedule) => {
      assert_eq(schedule.operations[1].machine_id, "m2")
      assert_eq(schedule.operations[1].start, 0)
    }
    Err(message) => fail(message)
  }
}
