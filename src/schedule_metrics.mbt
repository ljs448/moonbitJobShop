///|
pub fn Schedule::machine_load(self : Schedule, machine_id : String) -> Int {
  machine_load(self, machine_id)
}

///|
pub fn Schedule::machine_span(self : Schedule, machine_id : String) -> Int {
  let intervals = self.machine_intervals(machine_id)
  if intervals.length() == 0 {
    return 0
  }
  intervals[intervals.length() - 1].end - intervals[0].start
}

///|
pub fn Schedule::idle_time(self : Schedule, machine_id : String) -> Int {
  let span = self.machine_span(machine_id)
  let load = self.machine_load(machine_id)
  if span > load {
    span - load
  } else {
    0
  }
}

///|
pub fn Schedule::start_time(self : Schedule, job_id : String) -> Int {
  let operations = self.job_operations(job_id)
  if operations.length() == 0 {
    0
  } else {
    operations[0].start
  }
}

///|
pub fn Schedule::completion_time(self : Schedule, job_id : String) -> Int {
  let operations = self.job_operations(job_id)
  if operations.length() == 0 {
    0
  } else {
    operations[operations.length() - 1].end
  }
}

///|
pub fn Schedule::job_count(self : Schedule) -> Int {
  let ids : Array[String] = []
  for operation in self.operations {
    let mut found = false
    for id in ids {
      if id == operation.job_id {
        found = true
      }
    }
    if !found {
      ids.push(operation.job_id)
    }
  }
  ids.length()
}

///|
pub struct ScheduleStats {
  average_flow_time : Int
  average_waiting_time : Int
  total_waiting : Int
  total_setup : Int
  critical_length : Int
  utilization_percent : Array[Int]
  total_load : Int
} derive(Eq, Debug)

///|
pub fn schedule_stats(
  schedule : Schedule,
  jobs : Array[Job],
  machines : Array[Machine],
) -> ScheduleStats {
  let mut flow_total = 0
  let mut waiting_total = 0
  for job in jobs {
    flow_total += schedule.completion_time(job.id) - schedule.start_time(job.id)
    waiting_total += waiting_time(schedule, job.id)
  }
  let job_count = if jobs.length() == 0 { 1 } else { jobs.length() }
  let utilization : Array[Int] = []
  let mut total_load = 0
  for machine in machines {
    let load = schedule.machine_load(machine.id)
    total_load += load
    let span = schedule.makespan()
    utilization.push(if span == 0 { 0 } else { load * 100 / span })
  }
  {
    average_flow_time: flow_total / job_count,
    average_waiting_time: waiting_total / job_count,
    total_waiting: waiting_total,
    total_setup: total_setup_count(schedule),
    critical_length: critical_path(schedule).length(),
    utilization_percent: utilization,
    total_load,
  }
}

///|
pub fn ScheduleStats::summary(self : ScheduleStats) -> String {
  "flow=\{self.average_flow_time}, waiting=\{self.average_waiting_time}, total_waiting=\{self.total_waiting}, setups=\{self.total_setup}, critical=\{self.critical_length}, load=\{self.total_load}"
}
