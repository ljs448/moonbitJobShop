///|
test "validates operation duration and machine choices" {
  let machine = Machine::new(id="mill-1", name="Milling")
  let operation = Operation::new(
    id="op-1",
    name="Rough mill",
    duration=4,
    machine_ids=[machine.id],
    setup_group="steel",
  )
  let job = Job::new(id="job-1", name="Bracket", due_time=12, operations=[
    operation,
  ])
  assert_eq(job.validate([machine]), None)
  let broken = Operation::new(
    id="bad",
    name="Bad",
    duration=0,
    machine_ids=[],
    setup_group="",
  )
  assert_true(
    Job::new(id="bad-job", name="Bad", due_time=1, operations=[broken]).validate([
        machine,
      ],
    )
    is Some(_),
  )
}

///|
test "accepts alternative machine routes" {
  let machines = [
    Machine::new(id="mill-1", name="Milling 1"),
    Machine::new(id="mill-2", name="Milling 2"),
  ]
  let operation = Operation::new(
    id="op-1",
    name="Mill",
    duration=3,
    machine_ids=["mill-1", "mill-2"],
    setup_group="aluminum",
  )
  let input = ScheduleInput::new(
    jobs=[Job::new(id="job-1", name="Part", due_time=8, operations=[operation])],
    machines~,
    setup_times=[],
  )
  assert_eq(input.validate(), None)
}
