///|
fn sorted_intervals(intervals : Array[Interval]) -> Array[Interval] {
  let result : Array[Interval] = []
  for interval in intervals {
    let mut inserted = false
    for index in 0..<result.length() {
      if !inserted && interval.start < result[index].start {
        result.insert(index, interval)
        inserted = true
        break
      }
    }
    if !inserted {
      result.push(interval)
    }
  }
  result
}

///|
pub fn MachineCalendar::unavailable_count(self : MachineCalendar) -> Int {
  self.unavailable.length()
}

///|
pub fn MachineCalendar::covers(
  self : MachineCalendar,
  interval : Interval,
) -> Bool {
  for blocked in self.unavailable {
    if blocked.start <= interval.start && interval.end <= blocked.end {
      return true
    }
  }
  false
}

///|
pub fn MachineCalendar::working_time(
  self : MachineCalendar,
  until~ : Int,
) -> Int {
  if until <= 0 {
    return 0
  }
  let mut blocked = 0
  for interval in self.unavailable {
    let left = if interval.start < 0 { 0 } else { interval.start }
    let right = if interval.end > until { until } else { interval.end }
    if right > left {
      blocked += right - left
    }
  }
  if until > blocked {
    until - blocked
  } else {
    0
  }
}

///|
pub fn MachineCalendar::availability_gaps(
  self : MachineCalendar,
  until~ : Int,
) -> Array[Interval] {
  let gaps : Array[Interval] = []
  if until <= 0 {
    return gaps
  }
  let sorted = sorted_intervals(self.unavailable)
  let mut cursor = 0
  for interval in sorted {
    let start = if interval.start < 0 { 0 } else { interval.start }
    let end = if interval.end > until { until } else { interval.end }
    if start > cursor {
      gaps.push(Interval::new(start=cursor, end=start))
    }
    if end > cursor {
      cursor = end
    }
  }
  if cursor < until {
    gaps.push(Interval::new(start=cursor, end=until))
  }
  gaps
}

///|
pub fn MachineCalendar::next_gap(
  self : MachineCalendar,
  earliest~ : Int,
  duration~ : Int,
  until~ : Int,
) -> Interval? {
  for gap in self.availability_gaps(until~) {
    let start = if gap.start < earliest { earliest } else { gap.start }
    if start + duration <= gap.end {
      return Some(Interval::new(start~, end=start + duration))
    }
  }
  None
}

///|
pub fn MachineCalendar::available_ratio(
  self : MachineCalendar,
  until~ : Int,
) -> Int {
  if until <= 0 {
    0
  } else {
    self.working_time(until~) * 100 / until
  }
}

///|
pub fn MachineCalendar::describe(self : MachineCalendar) -> String {
  "machine=\{self.machine_id}, unavailable=\{self.unavailable.length()}, blocked=\{self.blocked_time()}"
}
