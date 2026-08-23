///|
pub enum ScheduleEvent {
  Insert(job~ : Job)
  Cancel(job_id~ : String)
  MachineOutage(machine_id~ : String, start~ : Int, end~ : Int)
} derive(Eq, Debug)

///|
pub fn ScheduleEvent::insert(job : Job) -> ScheduleEvent {
  Insert(job~)
}

///|
pub fn ScheduleEvent::cancel(job_id : String) -> ScheduleEvent {
  Cancel(job_id~)
}

///|
pub fn ScheduleEvent::machine_outage(
  machine_id : String,
  start : Int,
  end : Int,
) -> ScheduleEvent {
  MachineOutage(machine_id~, start~, end~)
}

///|
pub fn ScheduleEvent::label(self : ScheduleEvent) -> String {
  match self {
    Insert(job~) => "insert=\{job.id}"
    Cancel(job_id~) => "cancel=\{job_id}"
    MachineOutage(machine_id~, start~, end~) =>
      "outage=\{machine_id}:\{start}-\{end}"
  }
}

///|
pub fn ScheduleEvent::validate(
  self : ScheduleEvent,
  input : ScheduleInput,
) -> String? {
  match self {
    Insert(job~) =>
      if find_job(input, job.id) is Some(_) {
        Some("cannot insert a duplicate job")
      } else {
        job.validate(input.machines)
      }
    Cancel(job_id~) =>
      if find_job(input, job_id) is None {
        Some("cannot cancel an unknown job")
      } else {
        None
      }
    MachineOutage(machine_id~, start~, end~) =>
      if !has_machine(input, machine_id) {
        Some("machine outage references an unknown machine")
      } else if start < 0 || end <= start {
        Some("machine outage interval must be positive and non-negative")
      } else {
        None
      }
  }
}

///|
pub struct RescheduleOptions {
  dispatch : DispatchOptions
  frozen_until : Int
  keep_cancelled : Bool
} derive(Eq, Debug)

///|
pub fn RescheduleOptions::default() -> RescheduleOptions {
  {
    dispatch: DispatchOptions::default(),
    frozen_until: 0,
    keep_cancelled: false,
  }
}

///|
pub fn RescheduleOptions::with_frozen_until(
  self : RescheduleOptions,
  frozen_until : Int,
) -> RescheduleOptions {
  { ..self, frozen_until: if frozen_until < 0 { 0 } else { frozen_until } }
}

///|
pub fn RescheduleOptions::with_dispatch(
  self : RescheduleOptions,
  dispatch : DispatchOptions,
) -> RescheduleOptions {
  { ..self, dispatch, }
}

///|
pub fn RescheduleOptions::keep_cancelled_jobs(
  self : RescheduleOptions,
  keep : Bool,
) -> RescheduleOptions {
  { ..self, keep_cancelled: keep }
}

///|
pub struct RescheduleResult {
  input : ScheduleInput
  schedule : Schedule
  applied_events : Int
  cancelled_jobs : Array[String]
  warnings : Array[String]
  event_log : Array[String]
} derive(Eq, Debug)

///|
fn has_machine(input : ScheduleInput, machine_id : String) -> Bool {
  for machine in input.machines {
    if machine.id == machine_id {
      return true
    }
  }
  false
}

///|
fn remove_job(input : ScheduleInput, job_id : String) -> (ScheduleInput, Bool) {
  let jobs : Array[Job] = []
  let mut removed = false
  for job in input.jobs {
    if job.id == job_id {
      removed = true
    } else {
      jobs.push(job)
    }
  }
  ({ ..input, jobs, }, removed)
}

///|
fn append_job(input : ScheduleInput, job : Job) -> ScheduleInput {
  let jobs = input.jobs.copy()
  jobs.push(job)
  { ..input, jobs, }
}

///|
fn add_outage_to_options(
  options : DispatchOptions,
  machine_id : String,
  interval : Interval,
) -> Result[DispatchOptions, String] {
  let calendars = options.calendars.copy()
  for i in 0..<calendars.length() {
    if calendars[i].machine_id == machine_id {
      match calendars[i].add_unavailable(interval) {
        Err(message) => return Err(message)
        Ok(calendar) => {
          calendars[i] = calendar
          return Ok({ ..options, calendars, })
        }
      }
    }
  }
  let calendar = MachineCalendar::new(machine_id~)
  match calendar.add_unavailable(interval) {
    Err(message) => Err(message)
    Ok(calendar) => {
      calendars.push(calendar)
      Ok({ ..options, calendars, })
    }
  }
}

///|
pub fn reschedule(
  input : ScheduleInput,
  events : Array[ScheduleEvent],
  options : RescheduleOptions,
) -> Result[RescheduleResult, String] {
  let mut current_input = input
  let mut dispatch_options = options.dispatch.with_frozen_until(
    options.frozen_until,
  )
  let cancelled_jobs : Array[String] = []
  let warnings : Array[String] = []
  let event_log : Array[String] = []
  let mut applied = 0
  for event in events {
    match event.validate(current_input) {
      Some(message) => return Err(message)
      None => ()
    }
    match event {
      Insert(job~) => current_input = append_job(current_input, job)
      Cancel(job_id~) => {
        let (next_input, removed) = remove_job(current_input, job_id)
        current_input = next_input
        if removed {
          cancelled_jobs.push(job_id)
        }
      }
      MachineOutage(machine_id~, start~, end~) =>
        match
          add_outage_to_options(
            dispatch_options,
            machine_id,
            Interval::new(start~, end~),
          ) {
          Ok(next) => dispatch_options = next
          Err(message) => return Err(message)
        }
    }
    applied += 1
    event_log.push(event.label())
  }
  match dispatch_with_options(current_input, dispatch_options) {
    Ok(schedule) =>
      Ok({
        input: current_input,
        schedule,
        applied_events: applied,
        cancelled_jobs,
        warnings,
        event_log,
      })
    Err(message) => Err(message)
  }
}

///|
pub fn RescheduleResult::summary(self : RescheduleResult) -> String {
  "events=\{self.applied_events}, cancelled=\{self.cancelled_jobs.length()}, makespan=\{self.schedule.makespan()}, warnings=\{self.warnings.length()}"
}
