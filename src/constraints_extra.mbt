///|
pub struct ConstraintPolicy {
  due_dates_hard : Bool
  require_all_operations : Bool
  require_calendar_capacity : Bool
  tardiness_limit : Int
} derive(Eq, Debug)

///|
pub fn ConstraintPolicy::default() -> ConstraintPolicy {
  {
    due_dates_hard: false,
    require_all_operations: true,
    require_calendar_capacity: true,
    tardiness_limit: 0,
  }
}

///|
pub fn ConstraintPolicy::strict_due_dates() -> ConstraintPolicy {
  { ..ConstraintPolicy::default(), due_dates_hard: true }
}

///|
pub fn ConstraintPolicy::with_tardiness_limit(
  self : ConstraintPolicy,
  limit : Int,
) -> ConstraintPolicy {
  { ..self, tardiness_limit: if limit < 0 { 0 } else { limit } }
}

///|
pub fn ConstraintPolicy::without_calendar_capacity(
  self : ConstraintPolicy,
) -> ConstraintPolicy {
  { ..self, require_calendar_capacity: false }
}

///|
pub fn validate_with_policy(
  schedule : Schedule,
  input : ScheduleInput,
  policy : ConstraintPolicy,
  calendars : Array[MachineCalendar],
) -> ConstraintReport {
  let base = check_constraints(schedule, input, calendars)
  let violations : Array[ConstraintViolation] = []
  for item in base.violations {
    if item.code == "due-date" && policy.due_dates_hard {
      violations.push({ ..item, hard: true })
    } else {
      violations.push(item)
    }
  }
  if policy.require_all_operations {
    for job in input.jobs {
      for operation in job.operations {
        if !schedule.contains_operation(operation.id) {
          violations.push({
            code: "missing-operation",
            message: "operation is not scheduled",
            hard: true,
            job_id: job.id,
            operation_id: operation.id,
          })
        }
      }
    }
  }
  if policy.tardiness_limit > 0 {
    for job in input.jobs {
      let tardiness = schedule.completion_time(job.id) - job.due_time
      if tardiness > policy.tardiness_limit {
        violations.push({
          code: "tardiness-limit",
          message: "job exceeds the configured tardiness limit",
          hard: policy.due_dates_hard,
          job_id: job.id,
          operation_id: "",
        })
      }
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
pub fn constraint_counts(report : ConstraintReport) -> String {
  "hard=\{report.hard_violation_count()}, soft=\{report.soft_violation_count()}, total=\{report.violations.length()}"
}

///|
pub fn constraint_penalty_by_policy(
  report : ConstraintReport,
  hard_weight : Int,
  soft_weight : Int,
) -> Int {
  let hard = if hard_weight < 0 { 0 } else { hard_weight }
  let soft = if soft_weight < 0 { 0 } else { soft_weight }
  report.hard_violation_count() * hard + report.soft_violation_count() * soft
}

///|
pub fn missing_operation_ids(
  schedule : Schedule,
  input : ScheduleInput,
) -> Array[String] {
  let result : Array[String] = []
  for job in input.jobs {
    for operation in job.operations {
      if !schedule.contains_operation(operation.id) {
        result.push(operation.id)
      }
    }
  }
  result
}
