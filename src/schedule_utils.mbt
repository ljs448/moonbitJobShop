///|
fn operation_precedes(
  left : ScheduledOperation,
  right : ScheduledOperation,
) -> Bool {
  if left.start != right.start {
    left.start < right.start
  } else if left.end != right.end {
    left.end < right.end
  } else if left.job_id != right.job_id {
    left.job_id < right.job_id
  } else {
    left.operation_id < right.operation_id
  }
}

///|
fn sorted_scheduled(
  operations : Array[ScheduledOperation],
) -> Array[ScheduledOperation] {
  let sorted : Array[ScheduledOperation] = []
  for operation in operations {
    let mut inserted = false
    for i in 0..<sorted.length() {
      if !inserted && operation_precedes(operation, sorted[i]) {
        sorted.insert(i, operation)
        inserted = true
        break
      }
    }
    if !inserted {
      sorted.push(operation)
    }
  }
  sorted
}

///|
pub fn Schedule::machine_intervals(
  self : Schedule,
  machine_id : String,
) -> Array[ScheduledOperation] {
  let selected : Array[ScheduledOperation] = []
  for operation in self.operations {
    if operation.machine_id == machine_id {
      selected.push(operation)
    }
  }
  sorted_scheduled(selected)
}

///|
pub fn Schedule::job_operations(
  self : Schedule,
  job_id : String,
) -> Array[ScheduledOperation] {
  let selected : Array[ScheduledOperation] = []
  for operation in self.operations {
    if operation.job_id == job_id {
      selected.push(operation)
    }
  }
  sorted_scheduled(selected)
}

///|
pub fn Schedule::signature(self : Schedule) -> String {
  let sorted = sorted_scheduled(self.operations)
  let mut result = ""
  for i in 0..<sorted.length() {
    if i > 0 {
      result += "|"
    }
    let operation = sorted[i]
    result += "\{operation.job_id}:\{operation.operation_id}@\{operation.machine_id}:\{operation.start}-\{operation.end}"
  }
  result
}

///|
pub fn Schedule::operation_count(self : Schedule) -> Int {
  self.operations.length()
}

///|
pub fn Schedule::contains_operation(
  self : Schedule,
  operation_id : String,
) -> Bool {
  for operation in self.operations {
    if operation.operation_id == operation_id {
      return true
    }
  }
  false
}

///|
fn job_start(schedule : Schedule, job_id : String) -> Int {
  let operations = schedule.job_operations(job_id)
  if operations.length() == 0 {
    1_000_000_000
  } else {
    operations[0].start
  }
}

///|
pub fn Schedule::job_order(self : Schedule, jobs : Array[Job]) -> Array[Job] {
  let ordered : Array[Job] = []
  for job in jobs {
    let start = job_start(self, job.id)
    let mut inserted = false
    for i in 0..<ordered.length() {
      let current_start = job_start(self, ordered[i].id)
      if !inserted &&
        (
          start < current_start ||
          (start == current_start && job.id < ordered[i].id)
        ) {
        ordered.insert(i, job)
        inserted = true
        break
      }
    }
    if !inserted {
      ordered.push(job)
    }
  }
  ordered
}
