///|
pub struct MachineCapacity {
  machine_id : String
  horizon : Int
  blocked : Int
  available : Int
  demand : Int
  headroom : Int
  utilization : Int
} derive(Eq, Debug)

///|
pub struct CapacityProjection {
  horizon : Int
  machines : Array[MachineCapacity]
  total_capacity : Int
  blocked_capacity : Int
  total_demand : Int
} derive(Eq, Debug)

///|
fn calendar_for_machine(
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
fn machine_demand(input : ScheduleInput, machine_id : String) -> Int {
  let mut total = 0
  for job in input.jobs {
    for operation in job.operations {
      if operation.supports_machine(machine_id) {
        total += operation.duration
      }
    }
  }
  total
}

///|
pub fn project_capacity(
  input : ScheduleInput,
  calendars : Array[MachineCalendar],
  horizon~ : Int,
) -> CapacityProjection {
  let bounded_horizon = if horizon < 0 { 0 } else { horizon }
  let rows : Array[MachineCapacity] = []
  let mut total_capacity = 0
  let mut blocked_capacity = 0
  let mut total_demand = 0
  for machine in input.machines {
    let calendar = calendar_for_machine(calendars, machine.id)
    let blocked = bounded_horizon - calendar.working_time(until=bounded_horizon)
    let available = calendar.working_time(until=bounded_horizon)
    let demand = machine_demand(input, machine.id)
    let headroom = available - demand
    let utilization = if available == 0 { 0 } else { demand * 100 / available }
    rows.push({
      machine_id: machine.id,
      horizon: bounded_horizon,
      blocked,
      available,
      demand,
      headroom,
      utilization,
    })
    total_capacity += available
    blocked_capacity += blocked
    total_demand += demand
  }
  {
    horizon: bounded_horizon,
    machines: rows,
    total_capacity,
    blocked_capacity,
    total_demand,
  }
}

///|
pub fn capacity_overloaded_machines(
  projection : CapacityProjection,
) -> Array[String] {
  let result : Array[String] = []
  for row in projection.machines {
    if row.headroom < 0 {
      result.push(row.machine_id)
    }
  }
  result
}

///|
pub fn capacity_table(projection : CapacityProjection) -> String {
  let mut text = "machine,horizon,blocked,available,demand,headroom,utilization\n"
  for row in projection.machines {
    text += "\{row.machine_id},\{row.horizon},\{row.blocked},\{row.available},\{row.demand},\{row.headroom},\{row.utilization}\n"
  }
  text
}

///|
pub fn CapacityProjection::summary(self : CapacityProjection) -> String {
  "horizon=\{self.horizon}, machines=\{self.machines.length()}, capacity=\{self.total_capacity}, blocked=\{self.blocked_capacity}, demand=\{self.total_demand}, overloaded=\{capacity_overloaded_machines(self).length()}"
}

///|
pub fn capacity_utilization(projection : CapacityProjection) -> Int {
  if projection.total_capacity == 0 {
    0
  } else {
    projection.total_demand * 100 / projection.total_capacity
  }
}

///|
pub fn reschedule_with_capacity(
  input : ScheduleInput,
  outage_machine : String,
  outage : Interval,
  options : RescheduleOptions,
) -> Result[RescheduleResult, String] {
  reschedule(
    input,
    [ScheduleEvent::machine_outage(outage_machine, outage.start, outage.end)],
    options,
  )
}

///|
pub fn capacity_projection_text(projection : CapacityProjection) -> String {
  projection.summary() + "\n" + capacity_table(projection)
}

///|
pub fn capacity_signature(projection : CapacityProjection) -> String {
  let mut text = "\{projection.horizon}:"
  for row in projection.machines {
    text += "\{row.machine_id}=\{row.available}/\{row.demand};"
  }
  text
}
