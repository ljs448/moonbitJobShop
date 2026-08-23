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
  options : DispatchOptions,
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
  let selected_calendar = calendar_for(options.calendars, selected_id)
  let selected_start = selected_calendar.next_available(
    max_int(selected_start, options.frozen_until),
    operation.duration,
  )
  let mut best = (selected_id, selected_start)
  for machine_id in operation.machine_ids[1:] {
    let raw_start = max_int(
      ready_time,
      machines.get(machine_id).unwrap_or(0) +
      setup_duration(
        setups,
        groups.get(machine_id).unwrap_or(""),
        operation.setup_group,
      ),
    )
    let start = calendar_for(options.calendars, machine_id).next_available(
      max_int(raw_start, options.frozen_until),
      operation.duration,
    )
    if start < best.1 {
      best = (machine_id, start)
    }
  }
  best
}

///|
pub fn dispatch(input : ScheduleInput) -> Result[Schedule, String] {
  dispatch_with_options(input, DispatchOptions::default())
}

///|
pub fn dispatch_with_options(
  input : ScheduleInput,
  options : DispatchOptions,
) -> Result[Schedule, String] {
  match options.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  match input.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  let machine_available : Map[String, Int] = Map([])
  let machine_group : Map[String, String] = Map([])
  let scheduled : Array[ScheduledOperation] = []
  let jobs = priority_jobs(input.jobs, options)
  for job in jobs {
    let mut ready_time = 0
    for operation in job.operations {
      let (machine_id, start) = choose_machine(
        operation,
        ready_time,
        machine_available,
        machine_group,
        input.setup_times,
        options,
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
