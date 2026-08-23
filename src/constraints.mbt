///|
pub struct ConstraintViolation {
  code : String
  message : String
  hard : Bool
  job_id : String
  operation_id : String
} derive(Eq, Debug)

///|
pub struct ConstraintReport {
  feasible : Bool
  violations : Array[ConstraintViolation]
  checked_operations : Int
  checked_machines : Int
  checked_jobs : Int
} derive(Eq, Debug)

///|
fn violation(
  code : String,
  message : String,
  hard : Bool,
  job_id? : String = "",
  operation_id? : String = "",
) -> ConstraintViolation {
  { code, message, hard, job_id, operation_id }
}

///|
fn calendar_for_id(
  calendars : Array[MachineCalendar],
  machine_id : String,
) -> MachineCalendar? {
  for calendar in calendars {
    if calendar.machine_id == machine_id {
      return Some(calendar)
    }
  }
  None
}

///|
fn append_validation_violation(
  violations : Array[ConstraintViolation],
  message : String,
) -> Unit {
  violations.push(violation("input", message, true))
}

///|
pub fn check_constraints(
  schedule : Schedule,
  input : ScheduleInput,
  calendars : Array[MachineCalendar],
) -> ConstraintReport {
  let violations : Array[ConstraintViolation] = []
  match validate_schedule(schedule, input) {
    Some(message) => append_validation_violation(violations, message)
    None => ()
  }
  for operation in schedule.operations {
    match calendar_for_id(calendars, operation.machine_id) {
      Some(calendar) => {
        let interval = Interval::new(start=operation.start, end=operation.end)
        if !calendar.is_available(interval) {
          violations.push(
            violation(
              "calendar",
              "operation overlaps a machine outage",
              true,
              job_id=operation.job_id,
              operation_id=operation.operation_id,
            ),
          )
        }
      }
      None => ()
    }
  }
  for job in input.jobs {
    let completion = schedule.completion_time(job.id)
    if completion > job.due_time {
      violations.push(
        violation(
          "due-date",
          "job completes after its due time",
          false,
          job_id=job.id,
        ),
      )
    }
  }
  let mut hard_count = 0
  for item in violations {
    if item.hard {
      hard_count += 1
    }
  }
  {
    feasible: hard_count == 0,
    violations,
    checked_operations: schedule.operations.length(),
    checked_machines: input.machines.length(),
    checked_jobs: input.jobs.length(),
  }
}

///|
pub fn ConstraintReport::hard_violation_count(self : ConstraintReport) -> Int {
  let mut total = 0
  for item in self.violations {
    if item.hard {
      total += 1
    }
  }
  total
}

///|
pub fn ConstraintReport::soft_violation_count(self : ConstraintReport) -> Int {
  let mut total = 0
  for item in self.violations {
    if !item.hard {
      total += 1
    }
  }
  total
}

///|
pub fn ConstraintReport::is_feasible(self : ConstraintReport) -> Bool {
  self.feasible
}

///|
pub fn ConstraintReport::penalty(self : ConstraintReport) -> Int {
  self.hard_violation_count() * 100_000 + self.soft_violation_count() * 100
}

///|
pub fn ConstraintReport::summary(self : ConstraintReport) -> String {
  "feasible=\{self.feasible}, hard=\{self.hard_violation_count()}, soft=\{self.soft_violation_count()}, operations=\{self.checked_operations}, jobs=\{self.checked_jobs}, machines=\{self.checked_machines}"
}

///|
pub fn ConstraintReport::codes(self : ConstraintReport) -> Array[String] {
  let result : Array[String] = []
  for item in self.violations {
    result.push(item.code)
  }
  result
}

///|
pub fn is_schedule_feasible(schedule : Schedule, input : ScheduleInput) -> Bool {
  check_constraints(schedule, input, []).is_feasible()
}

///|
pub fn constraint_report_text(report : ConstraintReport) -> String {
  let mut text = report.summary() + "\n"
  for item in report.violations {
    text += "- \{item.code}: \{item.message}"
    if item.job_id != "" {
      text += " job=\{item.job_id}"
    }
    if item.operation_id != "" {
      text += " operation=\{item.operation_id}"
    }
    text += "\n"
  }
  text
}
