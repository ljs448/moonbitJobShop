///|
pub struct DispatchRule {
  code : Int
} derive(Eq, Debug)

///|
pub fn DispatchRule::fifo() -> DispatchRule {
  { code: 0 }
}

///|
pub fn DispatchRule::shortest_processing_time() -> DispatchRule {
  { code: 1 }
}

///|
pub fn DispatchRule::earliest_due_date() -> DispatchRule {
  { code: 2 }
}

///|
pub fn DispatchRule::least_slack() -> DispatchRule {
  { code: 3 }
}

///|
pub fn DispatchRule::setup_aware() -> DispatchRule {
  { code: 4 }
}

///|
pub struct DispatchTieBreaker {
  code : Int
} derive(Eq, Debug)

///|
pub fn DispatchTieBreaker::job_id() -> DispatchTieBreaker {
  { code: 0 }
}

///|
pub fn DispatchTieBreaker::due_time() -> DispatchTieBreaker {
  { code: 1 }
}

///|
pub fn DispatchTieBreaker::total_work() -> DispatchTieBreaker {
  { code: 2 }
}

///|
pub struct DispatchOptions {
  rule : DispatchRule
  calendars : Array[MachineCalendar]
  frozen_until : Int
  setup_penalty : Int
  tie_breaker : DispatchTieBreaker
} derive(Eq, Debug)

///|
pub fn DispatchOptions::default() -> DispatchOptions {
  {
    rule: DispatchRule::fifo(),
    calendars: [],
    frozen_until: 0,
    setup_penalty: 1,
    tie_breaker: DispatchTieBreaker::job_id(),
  }
}

///|
pub fn DispatchOptions::with_rule(
  self : DispatchOptions,
  rule : DispatchRule,
) -> DispatchOptions {
  { ..self, rule, }
}

///|
pub fn DispatchOptions::with_calendar(
  self : DispatchOptions,
  calendar : MachineCalendar,
) -> DispatchOptions {
  let calendars = self.calendars
  calendars.push(calendar)
  { ..self, calendars, }
}

///|
pub fn DispatchOptions::with_frozen_until(
  self : DispatchOptions,
  frozen_until : Int,
) -> DispatchOptions {
  { ..self, frozen_until: if frozen_until < 0 { 0 } else { frozen_until } }
}

///|
pub fn DispatchOptions::with_setup_penalty(
  self : DispatchOptions,
  setup_penalty : Int,
) -> DispatchOptions {
  { ..self, setup_penalty: if setup_penalty < 0 { 0 } else { setup_penalty } }
}

///|
pub fn DispatchOptions::with_tie_breaker(
  self : DispatchOptions,
  tie_breaker : DispatchTieBreaker,
) -> DispatchOptions {
  { ..self, tie_breaker, }
}

///|
pub fn DispatchOptions::validate(self : DispatchOptions) -> String? {
  if self.frozen_until < 0 {
    return Some("frozen prefix cannot be negative")
  }
  if self.setup_penalty < 0 {
    return Some("setup penalty cannot be negative")
  }
  for calendar in self.calendars {
    if calendar.machine_id == "" {
      return Some("calendar machine id cannot be empty")
    }
  }
  None
}

///|
fn calendar_for(
  calendars : Array[MachineCalendar],
  machine_id : String,
) -> MachineCalendar {
  for calendar in calendars {
    if calendar.machine_id == machine_id {
      return calendar
    }
  }
  MachineCalendar::new(machine_id~)
}

///|
fn operation_work(job : Job) -> Int {
  let mut total = 0
  for operation in job.operations {
    total += operation.duration
  }
  total
}

///|
fn job_priority_value(job : Job, rule : DispatchRule) -> Int {
  match rule.code {
    0 => 0
    1 => operation_work(job)
    2 => job.due_time
    3 => job.due_time - operation_work(job)
    _ => operation_work(job) + job.operations.length()
  }
}

///|
fn priority_precedes(
  left : Job,
  right : Job,
  options : DispatchOptions,
) -> Bool {
  let left_value = job_priority_value(left, options.rule)
  let right_value = job_priority_value(right, options.rule)
  if left_value != right_value {
    left_value < right_value
  } else {
    match options.tie_breaker.code {
      0 => left.id < right.id
      1 =>
        if left.due_time != right.due_time {
          left.due_time < right.due_time
        } else {
          left.id < right.id
        }
      _ => {
        let left_work = operation_work(left)
        let right_work = operation_work(right)
        if left_work != right_work {
          left_work < right_work
        } else {
          left.id < right.id
        }
      }
    }
  }
}

///|
fn priority_jobs(jobs : Array[Job], options : DispatchOptions) -> Array[Job] {
  if options.rule.code == 0 {
    return jobs
  }
  let sorted : Array[Job] = []
  for job in jobs {
    let mut inserted = false
    for i in 0..<sorted.length() {
      if !inserted && priority_precedes(job, sorted[i], options) {
        sorted.insert(i, job)
        inserted = true
        break
      }
    }
    if !inserted {
      sorted.push(job)
    }
  }
  sorted
}
