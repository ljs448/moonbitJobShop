///|
pub struct InputDiagnostics {
  jobs : Int
  machines : Int
  operations : Int
  total_work : Int
  flexible_operations : Int
  setup_rules : Int
  average_route_width : Int
  empty_due_dates : Int
} derive(Eq, Debug)

///|
pub struct MachineUsage {
  machine_id : String
  candidate_operations : Int
  candidate_work : Int
} derive(Eq, Debug)

///|
pub fn input_diagnostics(input : ScheduleInput) -> InputDiagnostics {
  let mut operations = 0
  let mut total_work = 0
  let mut flexible = 0
  let mut route_total = 0
  let mut empty_due_dates = 0
  for job in input.jobs {
    if job.due_time == 0 {
      empty_due_dates += 1
    }
    for operation in job.operations {
      operations += 1
      total_work += operation.duration
      route_total += operation.route_width()
      if operation.is_flexible() {
        flexible += 1
      }
    }
  }
  {
    jobs: input.jobs.length(),
    machines: input.machines.length(),
    operations,
    total_work,
    flexible_operations: flexible,
    setup_rules: input.setup_times.length(),
    average_route_width: if operations == 0 {
      0
    } else {
      route_total / operations
    },
    empty_due_dates,
  }
}

///|
pub fn diagnostics_summary(diagnostics : InputDiagnostics) -> String {
  "jobs=\{diagnostics.jobs}, machines=\{diagnostics.machines}, operations=\{diagnostics.operations}, work=\{diagnostics.total_work}, flexible=\{diagnostics.flexible_operations}, setup_rules=\{diagnostics.setup_rules}, average_route=\{diagnostics.average_route_width}"
}

///|
pub fn strict_input_check(input : ScheduleInput) -> Result[Unit, String] {
  match input.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  if input.jobs.length() == 0 {
    return Err("input must contain at least one job")
  }
  if input.operation_count() == 0 {
    return Err("input must contain at least one operation")
  }
  Ok(())
}

///|
pub fn input_operation_ids(input : ScheduleInput) -> Array[String] {
  let result : Array[String] = []
  for job in input.jobs {
    for operation in job.operations {
      result.push("\{job.id}/\{operation.id}")
    }
  }
  result
}

///|
pub fn input_machine_usage(input : ScheduleInput) -> Array[MachineUsage] {
  let result : Array[MachineUsage] = []
  for machine in input.machines {
    let mut count = 0
    let mut work = 0
    for job in input.jobs {
      for operation in job.operations {
        if operation.supports_machine(machine.id) {
          count += 1
          work += operation.duration
        }
      }
    }
    result.push({
      machine_id: machine.id,
      candidate_operations: count,
      candidate_work: work,
    })
  }
  result
}

///|
pub fn machine_usage_table(usage : Array[MachineUsage]) -> String {
  let mut text = "machine,candidate_operations,candidate_work\n"
  for item in usage {
    text += "\{item.machine_id},\{item.candidate_operations},\{item.candidate_work}\n"
  }
  text
}

///|
pub fn input_signature(input : ScheduleInput) -> String {
  let diagnostics = input_diagnostics(input)
  let mut text = "\{diagnostics.jobs}x\{diagnostics.machines}x\{diagnostics.operations}:"
  for id in input.job_ids() {
    text += id + ";"
  }
  text
}

///|
pub fn input_diagnostics_csv(input : ScheduleInput) -> String {
  let diagnostics = input_diagnostics(input)
  "field,value\n" +
  "jobs,\{diagnostics.jobs}\n" +
  "machines,\{diagnostics.machines}\n" +
  "operations,\{diagnostics.operations}\n" +
  "total_work,\{diagnostics.total_work}\n" +
  "flexible_operations,\{diagnostics.flexible_operations}\n"
}
