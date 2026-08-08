///|
fn main {
  let machine = @jobshop.Machine::new(id="mill-1", name="Mill")
  let job = @jobshop.Job::new(id="job-1", name="Demo part", due_time=12, operations=[
    @jobshop.Operation::new(
      id="op-1",
      name="Rough",
      duration=4,
      machine_ids=["mill-1"],
      setup_group="steel",
    ),
    @jobshop.Operation::new(
      id="op-2",
      name="Finish",
      duration=3,
      machine_ids=["mill-1"],
      setup_group="steel",
    ),
  ])
  let input = @jobshop.ScheduleInput::new(jobs=[job], machines=[machine], setup_times=[])
  match @jobshop.dispatch(input) {
    Ok(schedule) => {
      let report = @jobshop.summarize(schedule, [job], [machine])
      println("makespan=\{report.makespan}, tardiness=\{report.tardiness}")
      for event in report.gantt {
        println(
          "\{event.job_id}/\{event.operation_id} on \{event.machine_id}: \{event.start}-\{event.end}",
        )
      }
    }
    Err(message) => println("invalid schedule: \{message}")
  }
}
