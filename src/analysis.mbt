///|
pub struct BottleneckRecord {
  machine_id : String
  load : Int
  utilization_percent : Int
  operation_count : Int
  rank : Int
} derive(Eq, Debug)

///|
fn latest_operation(schedule : Schedule) -> ScheduledOperation? {
  if schedule.operations.length() == 0 {
    return None
  }
  let mut latest = schedule.operations[0]
  for operation in schedule.operations[1:] {
    if operation.end > latest.end ||
      (
        operation.end == latest.end &&
        operation.operation_id > latest.operation_id
      ) {
      latest = operation
    }
  }
  Some(latest)
}

///|
fn predecessor(
  schedule : Schedule,
  current : ScheduledOperation,
) -> ScheduledOperation? {
  let mut selected : ScheduledOperation? = None
  for operation in schedule.operations {
    if operation.job_id == current.job_id && operation.end <= current.start {
      match selected {
        Some(existing) =>
          if operation.end > existing.end {
            selected = Some(operation)
          }
        None => selected = Some(operation)
      }
    }
  }
  selected
}

///|
pub fn critical_path(schedule : Schedule) -> Array[ScheduledOperation] {
  let path : Array[ScheduledOperation] = []
  let mut current = latest_operation(schedule)
  for _ in 0..<schedule.operations.length() {
    match current {
      Some(operation) => {
        path.insert(0, operation)
        current = predecessor(schedule, operation)
      }
      None => break
    }
  }
  path
}

///|
fn bottleneck_precedes(
  left : BottleneckRecord,
  right : BottleneckRecord,
) -> Bool {
  if left.load != right.load {
    left.load > right.load
  } else if left.operation_count != right.operation_count {
    left.operation_count > right.operation_count
  } else {
    left.machine_id < right.machine_id
  }
}

///|
pub fn bottleneck_ranking(
  schedule : Schedule,
  machines : Array[Machine],
) -> Array[BottleneckRecord] {
  let span = schedule.makespan()
  let sorted : Array[BottleneckRecord] = []
  for machine in machines {
    let operations = schedule.machine_intervals(machine.id)
    let load = machine_load(schedule, machine.id)
    let percent = if span == 0 { 0 } else { load * 100 / span }
    let record = BottleneckRecord::{
      machine_id: machine.id,
      load,
      utilization_percent: percent,
      operation_count: operations.length(),
      rank: 0,
    }
    let mut inserted = false
    for i in 0..<sorted.length() {
      if !inserted && bottleneck_precedes(record, sorted[i]) {
        sorted.insert(i, record)
        inserted = true
        break
      }
    }
    if !inserted {
      sorted.push(record)
    }
  }
  for i in 0..<sorted.length() {
    let record = sorted[i]
    sorted[i] = { ..record, rank: i + 1 }
  }
  sorted
}

///|
pub fn flow_time(schedule : Schedule, job_id : String) -> Int {
  let operations = schedule.job_operations(job_id)
  if operations.length() == 0 {
    0
  } else {
    operations[operations.length() - 1].end - operations[0].start
  }
}

///|
pub fn waiting_time(schedule : Schedule, job_id : String) -> Int {
  let operations = schedule.job_operations(job_id)
  let mut processing = 0
  for operation in operations {
    processing += operation.end - operation.start
  }
  let flow = flow_time(schedule, job_id)
  if flow > processing {
    flow - processing
  } else {
    0
  }
}

///|
pub fn machine_setup_count(schedule : Schedule, machine_id : String) -> Int {
  let operations = schedule.machine_intervals(machine_id)
  let mut result = 0
  for i in 1..<operations.length() {
    if operations[i - 1].setup_group != operations[i].setup_group {
      result += 1
    }
  }
  result
}

///|
pub fn total_setup_count(schedule : Schedule) -> Int {
  let machine_ids : Array[String] = []
  for operation in schedule.operations {
    let mut found = false
    for machine_id in machine_ids {
      if machine_id == operation.machine_id {
        found = true
      }
    }
    if !found {
      machine_ids.push(operation.machine_id)
    }
  }
  let mut total = 0
  for machine_id in machine_ids {
    total += machine_setup_count(schedule, machine_id)
  }
  total
}
