///|
pub struct HorizonWindow {
  index : Int
  start : Int
  end : Int
  operation_count : Int
  busy_time : Int
  job_count : Int
} derive(Eq, Debug)

///|
fn overlap_duration(
  left_start : Int,
  left_end : Int,
  right_start : Int,
  right_end : Int,
) -> Int {
  let start = if left_start > right_start { left_start } else { right_start }
  let end = if left_end < right_end { left_end } else { right_end }
  if end > start {
    end - start
  } else {
    0
  }
}

///|
pub fn schedule_windows(
  schedule : Schedule,
  width~ : Int,
) -> Array[HorizonWindow] {
  if width <= 0 {
    return []
  }
  let count = schedule.makespan() / width + 1
  let result : Array[HorizonWindow] = []
  for index in 0..<count {
    let start = index * width
    let end = start + width
    let jobs : Array[String] = []
    let mut operation_count = 0
    let mut busy_time = 0
    for operation in schedule.operations {
      let busy = overlap_duration(operation.start, operation.end, start, end)
      if busy > 0 {
        operation_count += 1
        busy_time += busy
        if !jobs.contains(operation.job_id) {
          jobs.push(operation.job_id)
        }
      }
    }
    result.push({
      index,
      start,
      end,
      operation_count,
      busy_time,
      job_count: jobs.length(),
    })
  }
  result
}

///|
pub fn HorizonWindow::utilization(self : HorizonWindow) -> Int {
  if self.end <= self.start {
    0
  } else {
    self.busy_time * 100 / (self.end - self.start)
  }
}

///|
pub fn HorizonWindow::is_busy(self : HorizonWindow) -> Bool {
  self.busy_time > 0
}

///|
pub fn horizon_busy_windows(windows : Array[HorizonWindow]) -> Int {
  let mut total = 0
  for window in windows {
    if window.is_busy() {
      total += 1
    }
  }
  total
}

///|
pub fn horizon_peak_load(windows : Array[HorizonWindow]) -> Int {
  let mut peak = 0
  for window in windows {
    if window.busy_time > peak {
      peak = window.busy_time
    }
  }
  peak
}

///|
pub fn horizon_table(windows : Array[HorizonWindow]) -> String {
  let mut text = "index,start,end,operations,busy_time,jobs,utilization\n"
  for window in windows {
    text += "\{window.index},\{window.start},\{window.end},\{window.operation_count},\{window.busy_time},\{window.job_count},\{window.utilization()}\n"
  }
  text
}

///|
pub fn schedule_horizon_summary(schedule : Schedule, width : Int) -> String {
  let windows = schedule_windows(schedule, width~)
  "width=\{width}, windows=\{windows.length()}, busy_windows=\{horizon_busy_windows(windows)}, peak_load=\{horizon_peak_load(windows)}"
}

///|
pub fn horizon_operation_counts(windows : Array[HorizonWindow]) -> Array[Int] {
  let result : Array[Int] = []
  for window in windows {
    result.push(window.operation_count)
  }
  result
}

///|
pub fn horizon_capacity(windows : Array[HorizonWindow]) -> Int {
  let mut capacity = 0
  for window in windows {
    capacity += window.end - window.start
  }
  capacity
}

///|
pub fn horizon_occupancy(windows : Array[HorizonWindow]) -> Int {
  let mut occupancy = 0
  for window in windows {
    occupancy += window.busy_time
  }
  occupancy
}
