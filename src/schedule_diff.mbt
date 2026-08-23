///|
pub struct ScheduleChange {
  job_id : String
  operation_id : String
  old_machine_id : String
  new_machine_id : String
  old_start : Int
  new_start : Int
  delta : Int
} derive(Eq, Debug)

///|
pub struct ScheduleDiff {
  added : Array[ScheduledOperation]
  removed : Array[ScheduledOperation]
  moved : Array[ScheduleChange]
  delayed : Int
} derive(Eq, Debug)

///|
fn same_operation(
  left : ScheduledOperation,
  right : ScheduledOperation,
) -> Bool {
  left.job_id == right.job_id && left.operation_id == right.operation_id
}

///|
fn find_same_operation(
  operations : Array[ScheduledOperation],
  needle : ScheduledOperation,
) -> ScheduledOperation? {
  for operation in operations {
    if same_operation(operation, needle) {
      return Some(operation)
    }
  }
  None
}

///|
pub fn diff_schedules(before : Schedule, after : Schedule) -> ScheduleDiff {
  let added : Array[ScheduledOperation] = []
  let removed : Array[ScheduledOperation] = []
  let moved : Array[ScheduleChange] = []
  let mut delayed = 0
  for operation in after.operations {
    match find_same_operation(before.operations, operation) {
      None => added.push(operation)
      Some(previous) =>
        if previous.start != operation.start ||
          previous.machine_id != operation.machine_id {
          let delta = operation.start - previous.start
          moved.push({
            job_id: operation.job_id,
            operation_id: operation.operation_id,
            old_machine_id: previous.machine_id,
            new_machine_id: operation.machine_id,
            old_start: previous.start,
            new_start: operation.start,
            delta,
          })
          if delta > 0 {
            delayed += delta
          }
        }
    }
  }
  for operation in before.operations {
    if find_same_operation(after.operations, operation) is None {
      removed.push(operation)
    }
  }
  { added, removed, moved, delayed }
}

///|
pub fn ScheduleDiff::has_changes(self : ScheduleDiff) -> Bool {
  self.added.length() > 0 ||
  self.removed.length() > 0 ||
  self.moved.length() > 0
}

///|
pub fn ScheduleDiff::summary(self : ScheduleDiff) -> String {
  "added=\{self.added.length()}, removed=\{self.removed.length()}, moved=\{self.moved.length()}, delayed=\{self.delayed}"
}

///|
pub fn ScheduleDiff::change_count(self : ScheduleDiff) -> Int {
  self.added.length() + self.removed.length() + self.moved.length()
}
