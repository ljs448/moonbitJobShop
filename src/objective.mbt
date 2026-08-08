///|
pub fn makespan(schedule : Schedule) -> Int {
  schedule.makespan()
}

///|
fn job_end(schedule : Schedule, job_id : String) -> Int {
  let mut result = 0
  for operation in schedule.operations {
    if operation.job_id == job_id && operation.end > result {
      result = operation.end
    }
  }
  result
}

///|
pub fn total_tardiness(schedule : Schedule, jobs : Array[Job]) -> Int {
  let mut total = 0
  for job in jobs {
    let delay = job_end(schedule, job.id) - job.due_time
    if delay > 0 {
      total += delay
    }
  }
  total
}

///|
pub fn machine_load(schedule : Schedule, machine_id : String) -> Int {
  let mut total = 0
  for operation in schedule.operations {
    if operation.machine_id == machine_id {
      total += operation.end - operation.start
    }
  }
  total
}

///|
pub fn load_balance(schedule : Schedule, machines : Array[Machine]) -> Int {
  if machines.length() == 0 {
    return 0
  }
  let mut minimum = machine_load(schedule, machines[0].id)
  let mut maximum = minimum
  for machine in machines[1:] {
    let load = machine_load(schedule, machine.id)
    if load < minimum {
      minimum = load
    }
    if load > maximum {
      maximum = load
    }
  }
  maximum - minimum
}
