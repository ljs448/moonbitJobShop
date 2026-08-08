///|
test "objectives and report summarize a schedule" {
  let operations = [
    ScheduledOperation::new(
      job_id="j1",
      operation_id="o1",
      machine_id="m1",
      setup_group="steel",
      start=0,
      end=4,
    ),
    ScheduledOperation::new(
      job_id="j2",
      operation_id="o2",
      machine_id="m1",
      setup_group="steel",
      start=4,
      end=7,
    ),
  ]
  let schedule = Schedule::new(operations~)
  let jobs = [
    Job::new(id="j1", name="First", due_time=3, operations=[]),
    Job::new(id="j2", name="Second", due_time=10, operations=[]),
  ]
  assert_eq(makespan(schedule), 7)
  assert_eq(total_tardiness(schedule, jobs), 1)
  assert_eq(machine_load(schedule, "m1"), 7)
  let report = summarize(schedule, jobs, [Machine::new(id="m1", name="Cutter")])
  assert_eq(report.tardiness, 1)
  assert_eq(report.machine_utilization[0].utilization_percent, 100)
  assert_eq(report.gantt.length(), 2)
}
