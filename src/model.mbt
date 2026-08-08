///|
pub struct Machine {
  id : String
  name : String
} derive(Eq, Debug)

///|
pub fn Machine::new(id~ : String, name~ : String) -> Machine {
  { id, name }
}

///|
pub struct Operation {
  id : String
  name : String
  duration : Int
  machine_ids : Array[String]
  setup_group : String
} derive(Eq, Debug)

///|
pub fn Operation::new(
  id~ : String,
  name~ : String,
  duration~ : Int,
  machine_ids~ : Array[String],
  setup_group~ : String,
) -> Operation {
  { id, name, duration, machine_ids, setup_group }
}

///|
pub struct Job {
  id : String
  name : String
  due_time : Int
  operations : Array[Operation]
} derive(Eq, Debug)

///|
pub fn Job::new(
  id~ : String,
  name~ : String,
  due_time~ : Int,
  operations~ : Array[Operation],
) -> Job {
  { id, name, due_time, operations }
}

///|
pub struct SetupTime {
  from_group : String
  to_group : String
  duration : Int
} derive(Eq, Debug)

///|
pub fn SetupTime::new(
  from_group~ : String,
  to_group~ : String,
  duration~ : Int,
) -> SetupTime {
  { from_group, to_group, duration }
}

///|
pub struct ScheduleInput {
  jobs : Array[Job]
  machines : Array[Machine]
  setup_times : Array[SetupTime]
} derive(Eq, Debug)

///|
pub fn ScheduleInput::new(
  jobs~ : Array[Job],
  machines~ : Array[Machine],
  setup_times~ : Array[SetupTime],
) -> ScheduleInput {
  { jobs, machines, setup_times }
}

///|
fn find_machine(machines : Array[Machine], id : String) -> Machine? {
  for machine in machines {
    if machine.id == id {
      return Some(machine)
    }
  }
  None
}

///|
fn validate_operation(
  operation : Operation,
  machines : Array[Machine],
) -> String? {
  if operation.duration <= 0 {
    return Some("operation duration must be positive")
  }
  if operation.machine_ids.length() == 0 {
    return Some("operation must name at least one machine")
  }
  for machine_id in operation.machine_ids {
    if find_machine(machines, machine_id) is None {
      return Some("operation references an unknown machine")
    }
  }
  None
}

///|
pub fn Job::validate(self : Job, machines : Array[Machine]) -> String? {
  if self.id == "" || self.name == "" {
    return Some("job id and name must be non-empty")
  }
  if self.due_time < 0 {
    return Some("job due time cannot be negative")
  }
  if self.operations.length() == 0 {
    return Some("job must contain at least one operation")
  }
  for operation in self.operations {
    match validate_operation(operation, machines) {
      Some(message) => return Some(message)
      None => ()
    }
  }
  None
}

///|
pub fn ScheduleInput::validate(self : ScheduleInput) -> String? {
  if self.machines.length() == 0 {
    return Some("schedule must contain at least one machine")
  }
  for job in self.jobs {
    match job.validate(self.machines) {
      Some(message) => return Some(message)
      None => ()
    }
  }
  for setup in self.setup_times {
    if setup.duration < 0 {
      return Some("setup duration cannot be negative")
    }
  }
  None
}

///|
pub fn SetupTime::duration_between(
  self : SetupTime,
  from_group : String,
  to_group : String,
) -> Int {
  if self.from_group == from_group && self.to_group == to_group {
    self.duration
  } else {
    0
  }
}

///|
pub fn setup_duration(
  setups : Array[SetupTime],
  from_group : String,
  to_group : String,
) -> Int {
  for setup in setups {
    if setup.from_group == from_group && setup.to_group == to_group {
      return setup.duration
    }
  }
  0
}
