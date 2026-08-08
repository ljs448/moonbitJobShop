///|
pub struct MachineUtilization {
  machine_id : String
  load : Int
  utilization_percent : Int
} derive(Eq, Debug)

///|
pub struct ScheduleReport {
  makespan : Int
  tardiness : Int
  load_balance : Int
  machine_utilization : Array[MachineUtilization]
  gantt : Array[ScheduledOperation]
} derive(Eq, Debug)

///|
pub fn summarize(
  schedule : Schedule,
  jobs : Array[Job],
  machines : Array[Machine],
) -> ScheduleReport {
  let span = makespan(schedule)
  let utilization : Array[MachineUtilization] = []
  for machine in machines {
    let load = machine_load(schedule, machine.id)
    let percent = if span == 0 { 0 } else { load * 100 / span }
    utilization.push({
      machine_id: machine.id,
      load,
      utilization_percent: percent,
    })
  }
  {
    makespan: span,
    tardiness: total_tardiness(schedule, jobs),
    load_balance: load_balance(schedule, machines),
    machine_utilization: utilization,
    gantt: schedule.operations,
  }
}
