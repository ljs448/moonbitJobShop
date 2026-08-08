///|
pub struct ScheduledOperation {
  job_id : String
  operation_id : String
  machine_id : String
  setup_group : String
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn ScheduledOperation::new(
  job_id~ : String,
  operation_id~ : String,
  machine_id~ : String,
  setup_group~ : String,
  start~ : Int,
  end~ : Int,
) -> ScheduledOperation {
  { job_id, operation_id, machine_id, setup_group, start, end }
}

///|
pub struct Schedule {
  operations : Array[ScheduledOperation]
} derive(Eq, Debug)

///|
pub fn Schedule::new(operations~ : Array[ScheduledOperation]) -> Schedule {
  { operations, }
}

///|
pub fn Schedule::makespan(self : Schedule) -> Int {
  let mut maximum = 0
  for operation in self.operations {
    if operation.end > maximum {
      maximum = operation.end
    }
  }
  maximum
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn choose_machine(
  operation : Operation,
  ready_time : Int,
  machines : Map[String, Int],
  groups : Map[String, String],
  setups : Array[SetupTime],
) -> (String, Int) {
  let selected_id = operation.machine_ids[0]
  let selected_start = max_int(
    ready_time,
    machines.get(selected_id).unwrap_or(0) +
    setup_duration(
      setups,
      groups.get(selected_id).unwrap_or(""),
      operation.setup_group,
    ),
  )
  let mut best = (selected_id, selected_start)
  for machine_id in operation.machine_ids[1:] {
    let start = max_int(
      ready_time,
      machines.get(machine_id).unwrap_or(0) +
      setup_duration(
        setups,
        groups.get(machine_id).unwrap_or(""),
        operation.setup_group,
      ),
    )
    if start < best.1 {
      best = (machine_id, start)
    }
  }
  best
}

///|
pub fn dispatch(input : ScheduleInput) -> Result[Schedule, String] {
  match input.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  let machine_available : Map[String, Int] = Map([])
  let machine_group : Map[String, String] = Map([])
  let scheduled : Array[ScheduledOperation] = []
  for job in input.jobs {
    let mut ready_time = 0
    for operation in job.operations {
      let (machine_id, start) = choose_machine(
        operation,
        ready_time,
        machine_available,
        machine_group,
        input.setup_times,
      )
      let end = start + operation.duration
      scheduled.push(
        ScheduledOperation::new(
          job_id=job.id,
          operation_id=operation.id,
          machine_id~,
          setup_group=operation.setup_group,
          start~,
          end~,
        ),
      )
      machine_available[machine_id] = end
      machine_group[machine_id] = operation.setup_group
      ready_time = end
    }
  }
  Ok(Schedule::new(operations=scheduled))
}
