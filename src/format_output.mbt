///|
fn csv_cell(value : String) -> String {
  value
}

///|
pub fn Schedule::to_csv(self : Schedule) -> String {
  let sorted = sorted_scheduled(self.operations)
  let mut result = "job_id,operation_id,machine_id,setup_group,start,end\n"
  for operation in sorted {
    result += "\{csv_cell(operation.job_id)},\{csv_cell(operation.operation_id)},\{csv_cell(operation.machine_id)},\{csv_cell(operation.setup_group)},\{operation.start},\{operation.end}\n"
  }
  result
}

///|
fn gantt_bar(start : Int, end : Int, span : Int, width : Int) -> String {
  if width <= 0 || span <= 0 || end <= start {
    ""
  } else {
    let left = start * width / span
    let right = end * width / span
    let visible = if right <= left { 1 } else { right - left }
    let mut result = ""
    for _ in 0..<left {
      result += " "
    }
    for _ in 0..<visible {
      result += "#"
    }
    result
  }
}

///|
pub fn Schedule::ascii_gantt(
  self : Schedule,
  machines : Array[Machine],
  width~ : Int,
) -> String {
  let span = self.makespan()
  let mut result = ""
  for machine in machines {
    result += "\{machine.id} |"
    for operation in self.machine_intervals(machine.id) {
      result += gantt_bar(operation.start, operation.end, span, width)
    }
    result += "|\n"
  }
  result
}

///|
pub fn Schedule::summary(self : Schedule, jobs : Array[Job]) -> String {
  let report = summarize(self, jobs, [])
  "makespan=\{report.makespan}, tardiness=\{report.tardiness}, balance=\{report.load_balance}, operations=\{self.operations.length()}"
}

///|
pub fn Schedule::machine_loads(
  self : Schedule,
  machines : Array[Machine],
) -> Array[Int] {
  let loads : Array[Int] = []
  for machine in machines {
    loads.push(machine_load(self, machine.id))
  }
  loads
}

///|
pub fn Schedule::is_non_overlapping(self : Schedule) -> Bool {
  let machine_ids : Array[String] = []
  for operation in self.operations {
    let mut found = false
    for machine_id in machine_ids {
      if machine_id == operation.machine_id {
        found = true
      }
    }
    if !found {
      machine_ids.push(operation.machine_id)
    }
  }
  for machine_id in machine_ids {
    let intervals = self.machine_intervals(machine_id)
    for i in 1..<intervals.length() {
      if intervals[i - 1].end > intervals[i].start {
        return false
      }
    }
  }
  true
}
