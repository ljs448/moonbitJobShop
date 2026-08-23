///|
pub struct Interval {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn Interval::new(start~ : Int, end~ : Int) -> Interval {
  { start, end }
}

///|
pub fn Interval::try_new(start~ : Int, end~ : Int) -> Result[Interval, String] {
  if start < 0 {
    Err("interval start cannot be negative")
  } else if end <= start {
    Err("interval end must be greater than start")
  } else {
    Ok(Interval::new(start~, end~))
  }
}

///|
pub fn Interval::duration(self : Interval) -> Int {
  self.end - self.start
}

///|
pub fn Interval::overlaps(self : Interval, other : Interval) -> Bool {
  self.start < other.end && other.start < self.end
}

///|
pub fn Interval::touches(self : Interval, other : Interval) -> Bool {
  self.end == other.start || other.end == self.start
}

///|
pub fn Interval::contains(self : Interval, point : Int) -> Bool {
  self.start <= point && point < self.end
}

///|
pub struct MachineCalendar {
  machine_id : String
  unavailable : Array[Interval]
} derive(Eq, Debug)

///|
pub fn MachineCalendar::new(machine_id~ : String) -> MachineCalendar {
  { machine_id, unavailable: [] }
}

///|
pub fn MachineCalendar::add_unavailable(
  self : MachineCalendar,
  interval : Interval,
) -> Result[MachineCalendar, String] {
  if interval.start < 0 || interval.end <= interval.start {
    return Err("unavailable interval must be positive and non-negative")
  }
  for existing in self.unavailable {
    if existing.overlaps(interval) {
      return Err("unavailable intervals cannot overlap")
    }
  }
  let unavailable = self.unavailable.copy()
  unavailable.push(interval)
  Ok({ ..self, unavailable, })
}

///|
fn max_calendar_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
pub fn MachineCalendar::next_available(
  self : MachineCalendar,
  earliest : Int,
  duration : Int,
) -> Int {
  if duration <= 0 {
    return max_calendar_int(earliest, 0)
  }
  let mut candidate = max_calendar_int(earliest, 0)
  let passes = self.unavailable.length() + 1
  for _ in 0..<passes {
    let mut next = candidate
    let current = Interval::new(start=candidate, end=candidate + duration)
    for blocked in self.unavailable {
      if current.overlaps(blocked) && blocked.end > next {
        next = blocked.end
      }
    }
    if next == candidate {
      return candidate
    }
    candidate = next
  }
  candidate
}

///|
pub fn MachineCalendar::is_available(
  self : MachineCalendar,
  interval : Interval,
) -> Bool {
  for blocked in self.unavailable {
    if interval.overlaps(blocked) {
      return false
    }
  }
  true
}

///|
pub fn MachineCalendar::blocked_time(self : MachineCalendar) -> Int {
  let mut total = 0
  for interval in self.unavailable {
    total += interval.duration()
  }
  total
}
