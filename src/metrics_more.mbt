///|
pub struct LatenessBucket {
  lower : Int
  upper : Int
  jobs : Int
} derive(Eq, Debug)

///|
pub struct MachineLoadBand {
  machine_id : String
  load : Int
  capacity : Int
  utilization : Int
  band : String
} derive(Eq, Debug)

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
pub fn schedule_histogram(schedule : Schedule, width : Int) -> Array[Int] {
  if width <= 0 || schedule.makespan() == 0 {
    return [0]
  }
  let bucket_count = schedule.makespan() / width + 1
  let result : Array[Int] = []
  for _ in 0..<bucket_count {
    result.push(0)
  }
  for operation in schedule.operations {
    let mut bucket = operation.start / width
    if bucket < 0 {
      bucket = 0
    }
    if bucket >= result.length() {
      bucket = result.length() - 1
    }
    result[bucket] += operation.end - operation.start
  }
  result
}

///|
pub fn lateness_buckets(
  schedule : Schedule,
  jobs : Array[Job],
  width : Int,
) -> Array[LatenessBucket] {
  if width <= 0 {
    return []
  }
  let maximum = schedule.makespan()
  let bucket_count = maximum / width + 1
  let result : Array[LatenessBucket] = []
  for index in 0..<bucket_count {
    let lower = index * width
    result.push({ lower, upper: lower + width, jobs: 0 })
  }
  for job in jobs {
    let completion = schedule.completion_time(job.id)
    let late = if completion > job.due_time {
      completion - job.due_time
    } else {
      0
    }
    let mut index = late / width
    if index >= result.length() {
      index = result.length() - 1
    }
    let bucket = result[index]
    result[index] = { ..bucket, jobs: bucket.jobs + 1 }
  }
  result
}

///|
pub fn late_job_ids(schedule : Schedule, jobs : Array[Job]) -> Array[String] {
  let result : Array[String] = []
  for job in jobs {
    if schedule.completion_time(job.id) > job.due_time {
      result.push(job.id)
    }
  }
  result
}

///|
pub fn earliest_completion(schedule : Schedule, jobs : Array[Job]) -> Int {
  if jobs.length() == 0 {
    return 0
  }
  let mut value = schedule.completion_time(jobs[0].id)
  for job in jobs[1:] {
    let completion = schedule.completion_time(job.id)
    if completion < value {
      value = completion
    }
  }
  value
}

///|
pub fn latest_due_time(jobs : Array[Job]) -> Int {
  let mut value = 0
  for job in jobs {
    if job.due_time > value {
      value = job.due_time
    }
  }
  value
}

///|
pub fn average_setup_duration(
  schedule : Schedule,
  input : ScheduleInput,
) -> Int {
  let mut total = 0
  let mut count = 0
  for machine in input.machines {
    let intervals = schedule.machine_intervals(machine.id)
    let mut previous : ScheduledOperation? = None
    for current in intervals {
      match previous {
        Some(last) => {
          total += setup_duration(
            input.setup_times,
            last.setup_group,
            current.setup_group,
          )
          count += 1
        }
        None => ()
      }
      previous = Some(current)
    }
  }
  if count == 0 {
    0
  } else {
    total / count
  }
}

///|
pub fn schedule_load_bands(
  schedule : Schedule,
  machines : Array[Machine],
) -> Array[MachineLoadBand] {
  let result : Array[MachineLoadBand] = []
  let horizon = schedule.makespan()
  for machine in machines {
    let load = schedule.machine_load(machine.id)
    let utilization = if horizon == 0 { 0 } else { load * 100 / horizon }
    let band = if utilization >= 80 {
      "high"
    } else if utilization >= 50 {
      "balanced"
    } else {
      "low"
    }
    result.push({
      machine_id: machine.id,
      load,
      capacity: horizon,
      utilization,
      band,
    })
  }
  result
}

///|
pub fn resource_balance_score(
  schedule : Schedule,
  machines : Array[Machine],
) -> Int {
  let bands = schedule_load_bands(schedule, machines)
  if bands.length() < 2 {
    return 100
  }
  let mut minimum = bands[0].utilization
  let mut maximum = bands[0].utilization
  for band in bands[1:] {
    if band.utilization < minimum {
      minimum = band.utilization
    }
    if band.utilization > maximum {
      maximum = band.utilization
    }
  }
  let score = 100 - (maximum - minimum)
  if score < 0 {
    0
  } else {
    score
  }
}

///|
pub fn critical_load_ratio(
  schedule : Schedule,
  machines : Array[Machine],
) -> Int {
  if machines.length() == 0 || schedule.makespan() == 0 {
    return 0
  }
  let mut maximum = 0
  for machine in machines {
    let load = schedule.machine_load(machine.id)
    if load > maximum {
      maximum = load
    }
  }
  maximum * 100 / schedule.makespan()
}

///|
pub fn dashboard_kpi_csv(
  schedule : Schedule,
  jobs : Array[Job],
  machines : Array[Machine],
) -> String {
  let dashboard = dashboard_metrics(schedule, jobs, machines)
  let mut text = "metric,value\n"
  text += "makespan,\{dashboard.makespan}\n"
  text += "on_time_rate,\{dashboard.on_time_rate}\n"
  text += "throughput,\{dashboard.throughput}\n"
  text += "weighted_tardiness,\{dashboard.weighted_tardiness}\n"
  text += "energy_units,\{dashboard.energy_units}\n"
  text += "balance_score,\{resource_balance_score(schedule, machines)}\n"
  text += "critical_load_ratio,\{critical_load_ratio(schedule, machines)}\n"
  text
}

///|
pub fn metrics_more_summary(
  schedule : Schedule,
  jobs : Array[Job],
  machines : Array[Machine],
) -> String {
  "makespan=\{schedule.makespan()}, earliest_completion=\{earliest_completion(schedule, jobs)}, latest_due=\{latest_due_time(jobs)}, late_jobs=\{late_job_ids(schedule, jobs).length()}, balance=\{resource_balance_score(schedule, machines)}"
}

///|
pub fn lateness_bucket_table(buckets : Array[LatenessBucket]) -> String {
  let mut text = "lower,upper,jobs\n"
  for bucket in buckets {
    text += "\{bucket.lower},\{bucket.upper},\{bucket.jobs}\n"
  }
  text
}

///|
pub fn load_band_table(bands : Array[MachineLoadBand]) -> String {
  let mut text = "machine,load,capacity,utilization,band\n"
  for band in bands {
    text += "\{band.machine_id},\{band.load},\{band.capacity},\{band.utilization},\{band.band}\n"
  }
  text
}

///|
pub fn schedule_variability(schedule : Schedule) -> Int {
  if schedule.operations.length() < 2 {
    return 0
  }
  let mut average = 0
  for operation in schedule.operations {
    average += operation.start
  }
  average /= schedule.operations.length()
  let mut deviation = 0
  for operation in schedule.operations {
    deviation += abs_int(operation.start - average)
  }
  deviation / schedule.operations.length()
}
