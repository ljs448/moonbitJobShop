///|
fn find_job(input : ScheduleInput, job_id : String) -> Job? {
  for job in input.jobs {
    if job.id == job_id {
      return Some(job)
    }
  }
  None
}

///|
fn find_job_operation(job : Job, operation_id : String) -> Operation? {
  for operation in job.operations {
    if operation.id == operation_id {
      return Some(operation)
    }
  }
  None
}

///|
fn find_scheduled_operation(
  schedule : Schedule,
  job_id : String,
  operation_id : String,
) -> ScheduledOperation? {
  for operation in schedule.operations {
    if operation.job_id == job_id && operation.operation_id == operation_id {
      return Some(operation)
    }
  }
  None
}

///|
fn has_duplicate_string(values : Array[String]) -> Bool {
  for i in 0..<values.length() {
    for j in (i + 1)..<values.length() {
      if values[i] == values[j] {
        return true
      }
    }
  }
  false
}

///|
fn validate_unique_input_ids(input : ScheduleInput) -> String? {
  let job_ids : Array[String] = []
  let machine_ids : Array[String] = []
  let operation_ids : Array[String] = []
  for machine in input.machines {
    machine_ids.push(machine.id)
  }
  if has_duplicate_string(machine_ids) {
    return Some("machine ids must be unique")
  }
  for job in input.jobs {
    job_ids.push(job.id)
    for operation in job.operations {
      operation_ids.push("\{job.id}/\{operation.id}")
    }
  }
  if has_duplicate_string(job_ids) {
    return Some("job ids must be unique")
  }
  if has_duplicate_string(operation_ids) {
    return Some("operation ids must be unique within their jobs")
  }
  None
}

///|
fn validate_scheduled_operation(
  operation : ScheduledOperation,
  input : ScheduleInput,
) -> String? {
  if operation.start < 0 || operation.end <= operation.start {
    return Some(
      "scheduled operation must have a positive non-negative interval",
    )
  }
  let job = match find_job(input, operation.job_id) {
    Some(value) => value
    None => return Some("schedule references an unknown job")
  }
  let source = match find_job_operation(job, operation.operation_id) {
    Some(value) => value
    None => return Some("schedule references an unknown operation")
  }
  if source.duration != operation.end - operation.start {
    return Some("scheduled duration differs from the operation duration")
  }
  let mut found_machine = false
  for machine in source.machine_ids {
    if machine == operation.machine_id {
      found_machine = true
    }
  }
  if !found_machine {
    return Some("scheduled operation uses an unavailable machine")
  }
  None
}

///|
pub fn validate_schedule(schedule : Schedule, input : ScheduleInput) -> String? {
  match input.validate() {
    Some(message) => return Some(message)
    None => ()
  }
  match validate_unique_input_ids(input) {
    Some(message) => return Some(message)
    None => ()
  }
  for operation in schedule.operations {
    match validate_scheduled_operation(operation, input) {
      Some(message) => return Some(message)
      None => ()
    }
  }
  for i in 0..<schedule.operations.length() {
    let left = schedule.operations[i]
    for j in (i + 1)..<schedule.operations.length() {
      let right = schedule.operations[j]
      if left.job_id == right.job_id && left.operation_id == right.operation_id {
        return Some("schedule contains a duplicate operation")
      }
      if left.machine_id == right.machine_id {
        let first = Interval::new(start=left.start, end=left.end)
        let second = Interval::new(start=right.start, end=right.end)
        if first.overlaps(second) {
          return Some("machine operations cannot overlap")
        }
      }
    }
  }
  for job in input.jobs {
    for i in 0..<job.operations.length() {
      let current = match
        find_scheduled_operation(schedule, job.id, job.operations[i].id) {
        Some(value) => value
        None => return Some("schedule does not cover every input operation")
      }
      if i + 1 < job.operations.length() {
        let next = match
          find_scheduled_operation(schedule, job.id, job.operations[i + 1].id) {
          Some(value) => value
          None => return Some("schedule does not cover every input operation")
        }
        if current.end > next.start {
          return Some("job operations must preserve precedence")
        }
      }
    }
  }
  None
}
