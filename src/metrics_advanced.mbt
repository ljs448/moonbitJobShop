///|
pub struct JobMetric {
  job_id : String
  start : Int
  completion : Int
  due_time : Int
  lateness : Int
  earliness : Int
  flow_time : Int
  waiting_time : Int
  on_time : Bool
} derive(Eq, Debug)

///|
pub struct MachineMetric {
  machine_id : String
  load : Int
  span : Int
  idle : Int
  utilization_percent : Int
  setup_count : Int
} derive(Eq, Debug)

///|
pub struct DashboardMetrics {
  jobs : Array[JobMetric]
  machines : Array[MachineMetric]
  makespan : Int
  on_time_rate : Int
  throughput : Int
  weighted_tardiness : Int
  energy_units : Int
} derive(Eq, Debug)

///|
pub fn job_metric(schedule : Schedule, job : Job) -> JobMetric {
  let start = schedule.start_time(job.id)
  let completion = schedule.completion_time(job.id)
  let late = if completion > job.due_time {
    completion - job.due_time
  } else {
    0
  }
  let early = if job.due_time > completion {
    job.due_time - completion
  } else {
    0
  }
  {
    job_id: job.id,
    start,
    completion,
    due_time: job.due_time,
    lateness: late,
    earliness: early,
    flow_time: completion - start,
    waiting_time: waiting_time(schedule, job.id),
    on_time: late == 0,
  }
}

///|
pub fn job_metrics(schedule : Schedule, jobs : Array[Job]) -> Array[JobMetric] {
  let result : Array[JobMetric] = []
  for job in jobs {
    result.push(job_metric(schedule, job))
  }
  result
}

///|
pub fn machine_metric(schedule : Schedule, machine : Machine) -> MachineMetric {
  {
    machine_id: machine.id,
    load: schedule.machine_load(machine.id),
    span: schedule.machine_span(machine.id),
    idle: schedule.idle_time(machine.id),
    utilization_percent: if schedule.makespan() == 0 {
      0
    } else {
      schedule.machine_load(machine.id) * 100 / schedule.makespan()
    },
    setup_count: machine_setup_count(schedule, machine.id),
  }
}

///|
pub fn machine_metrics(
  schedule : Schedule,
  machines : Array[Machine],
) -> Array[MachineMetric] {
  let result : Array[MachineMetric] = []
  for machine in machines {
    result.push(machine_metric(schedule, machine))
  }
  result
}

///|
pub fn on_time_job_count(schedule : Schedule, jobs : Array[Job]) -> Int {
  let mut count = 0
  for metric in job_metrics(schedule, jobs) {
    if metric.on_time {
      count += 1
    }
  }
  count
}

///|
pub fn on_time_rate(schedule : Schedule, jobs : Array[Job]) -> Int {
  if jobs.length() == 0 {
    0
  } else {
    on_time_job_count(schedule, jobs) * 100 / jobs.length()
  }
}

///|
pub fn throughput(
  schedule : Schedule,
  jobs : Array[Job],
  horizon~ : Int,
) -> Int {
  let mut count = 0
  for job in jobs {
    if schedule.completion_time(job.id) <= horizon {
      count += 1
    }
  }
  count
}

///|
pub fn weighted_tardiness(schedule : Schedule, jobs : Array[Job]) -> Int {
  let mut total = 0
  for job in jobs {
    let metric = job_metric(schedule, job)
    total += metric.lateness * (1 + job.operations.length())
  }
  total
}

///|
pub fn energy_estimate(
  schedule : Schedule,
  machines : Array[Machine],
  active_power~ : Int,
  idle_power~ : Int,
) -> Int {
  let mut total = 0
  for machine in machines {
    let metric = machine_metric(schedule, machine)
    total += metric.load * active_power + metric.idle * idle_power
  }
  total
}

///|
pub fn dashboard_metrics(
  schedule : Schedule,
  jobs : Array[Job],
  machines : Array[Machine],
) -> DashboardMetrics {
  {
    jobs: job_metrics(schedule, jobs),
    machines: machine_metrics(schedule, machines),
    makespan: schedule.makespan(),
    on_time_rate: on_time_rate(schedule, jobs),
    throughput: throughput(schedule, jobs, horizon=schedule.makespan()),
    weighted_tardiness: weighted_tardiness(schedule, jobs),
    energy_units: energy_estimate(
      schedule,
      machines,
      active_power=5,
      idle_power=1,
    ),
  }
}

///|
pub fn DashboardMetrics::summary(self : DashboardMetrics) -> String {
  "makespan=\{self.makespan}, on_time=\{self.on_time_rate}%, throughput=\{self.throughput}, weighted_tardiness=\{self.weighted_tardiness}, energy=\{self.energy_units}"
}

///|
pub fn job_metric_table(metrics : Array[JobMetric]) -> String {
  let mut text = "job_id,start,completion,due,lateness,waiting,on_time\n"
  for metric in metrics {
    text += "\{metric.job_id},\{metric.start},\{metric.completion},\{metric.due_time},\{metric.lateness},\{metric.waiting_time},\{metric.on_time}\n"
  }
  text
}
