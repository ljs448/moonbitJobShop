///|
pub fn Operation::supports_machine(
  self : Operation,
  machine_id : String,
) -> Bool {
  for candidate in self.machine_ids {
    if candidate == machine_id {
      return true
    }
  }
  false
}

///|
pub fn Operation::route_width(self : Operation) -> Int {
  self.machine_ids.length()
}

///|
pub fn Operation::is_flexible(self : Operation) -> Bool {
  self.machine_ids.length() > 1
}

///|
pub fn Operation::is_valid_duration(self : Operation) -> Bool {
  self.duration > 0
}

///|
pub fn Job::total_work(self : Job) -> Int {
  let mut total = 0
  for operation in self.operations {
    total += operation.duration
  }
  total
}

///|
pub fn Job::operation_index(self : Job, operation_id : String) -> Int? {
  for index, operation in self.operations {
    if operation.id == operation_id {
      return Some(index)
    }
  }
  None
}

///|
pub fn Job::flexible_operation_count(self : Job) -> Int {
  let mut total = 0
  for operation in self.operations {
    if operation.is_flexible() {
      total += 1
    }
  }
  total
}

///|
pub fn Job::slack_at(self : Job, elapsed : Int) -> Int {
  self.due_time - elapsed - self.total_work()
}

///|
pub fn ScheduleInput::operation_count(self : ScheduleInput) -> Int {
  let mut total = 0
  for job in self.jobs {
    total += job.operations.length()
  }
  total
}

///|
pub fn ScheduleInput::total_work(self : ScheduleInput) -> Int {
  let mut total = 0
  for job in self.jobs {
    total += job.total_work()
  }
  total
}

///|
pub fn ScheduleInput::find_machine(
  self : ScheduleInput,
  machine_id : String,
) -> Machine? {
  find_machine(self.machines, machine_id)
}

///|
pub fn ScheduleInput::find_job(self : ScheduleInput, job_id : String) -> Job? {
  find_job(self, job_id)
}

///|
pub fn ScheduleInput::machine_ids(self : ScheduleInput) -> Array[String] {
  let result : Array[String] = []
  for machine in self.machines {
    result.push(machine.id)
  }
  result
}

///|
pub fn ScheduleInput::job_ids(self : ScheduleInput) -> Array[String] {
  let result : Array[String] = []
  for job in self.jobs {
    result.push(job.id)
  }
  result
}

///|
pub fn ScheduleInput::setup_time_between(
  self : ScheduleInput,
  from_group : String,
  to_group : String,
) -> Int {
  setup_duration(self.setup_times, from_group, to_group)
}

///|
pub fn ScheduleInput::flexible_operation_count(self : ScheduleInput) -> Int {
  let mut total = 0
  for job in self.jobs {
    total += job.flexible_operation_count()
  }
  total
}

///|
pub fn ScheduleInput::is_empty(self : ScheduleInput) -> Bool {
  self.jobs.length() == 0 || self.operation_count() == 0
}

///|
pub fn ScheduleInput::describe(self : ScheduleInput) -> String {
  "jobs=\{self.jobs.length()}, machines=\{self.machines.length()}, operations=\{self.operation_count()}, work=\{self.total_work()}, flexible=\{self.flexible_operation_count()}"
}
