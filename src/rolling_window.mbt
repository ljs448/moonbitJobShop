///|
pub struct RollingWindow {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn RollingWindow::try_new(
  start~ : Int,
  end~ : Int,
) -> Result[RollingWindow, String] {
  if start < 0 {
    Err("rolling window start cannot be negative")
  } else if end <= start {
    Err("rolling window end must be greater than start")
  } else {
    Ok({ start, end })
  }
}

///|
pub fn RollingWindow::duration(self : RollingWindow) -> Int {
  self.end - self.start
}

///|
pub fn RollingWindow::contains(self : RollingWindow, time : Int) -> Bool {
  self.start <= time && time < self.end
}

///|
pub fn RollingWindow::overlaps(
  self : RollingWindow,
  interval : Interval,
) -> Bool {
  self.start < interval.end && interval.start < self.end
}

///|
pub fn reschedule_window(
  input : ScheduleInput,
  window : RollingWindow,
  events : Array[ScheduleEvent],
  options : RescheduleOptions,
) -> Result[RescheduleResult, String] {
  let bounded = options.with_frozen_until(window.start)
  reschedule(input, events, bounded)
}

///|
pub fn window_operations(
  schedule : Schedule,
  window : RollingWindow,
) -> Array[ScheduledOperation] {
  let result : Array[ScheduledOperation] = []
  for operation in schedule.operations {
    if window.overlaps(Interval::new(start=operation.start, end=operation.end)) {
      result.push(operation)
    }
  }
  result
}

///|
pub fn frozen_operations(
  schedule : Schedule,
  until~ : Int,
) -> Array[ScheduledOperation] {
  let result : Array[ScheduledOperation] = []
  for operation in schedule.operations {
    if operation.end <= until {
      result.push(operation)
    }
  }
  result
}

///|
pub fn RollingWindow::describe(self : RollingWindow) -> String {
  "window=\{self.start}-\{self.end}, duration=\{self.duration()}"
}
