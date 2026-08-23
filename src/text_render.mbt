///|
pub fn schedule_to_json(schedule : Schedule) -> String {
  let mut result = "{\"makespan\":\{schedule.makespan()},\"operations\":["
  let sorted = sorted_scheduled(schedule.operations)
  for i in 0..<sorted.length() {
    if i > 0 {
      result += ","
    }
    let operation = sorted[i]
    result += "{\"job_id\":\"\{operation.job_id}\",\"operation_id\":\"\{operation.operation_id}\",\"machine_id\":\"\{operation.machine_id}\",\"start\":\{operation.start},\"end\":\{operation.end}}"
  }
  result += "]}"
  result
}

///|
pub fn machine_gantt_rows(
  schedule : Schedule,
  machines : Array[Machine],
) -> Array[String] {
  let rows : Array[String] = []
  for machine in machines {
    let mut row = machine.id + ":"
    for operation in schedule.machine_intervals(machine.id) {
      row += " \{operation.job_id}/\{operation.operation_id}[\{operation.start},\{operation.end})"
    }
    rows.push(row)
  }
  rows
}

///|
pub fn render_schedule_text(schedule : Schedule) -> String {
  "makespan=\{schedule.makespan()}\noperation_count=\{schedule.operations.length()}\nsignature=\{schedule.signature()}"
}

///|
pub fn render_summary_table(reports : Array[ScheduleReport]) -> String {
  let mut result = "makespan,tardiness,load_balance,machine_count\n"
  for report in reports {
    result += "\{report.makespan},\{report.tardiness},\{report.load_balance},\{report.machine_utilization.length()}\n"
  }
  result
}

///|
pub fn render_benchmark_table(summaries : Array[BenchmarkSummary]) -> String {
  let mut result = "jobs,machines,operations,repeats,makespan,tardiness,score,checksum\n"
  for summary in summaries {
    result += "\{summary.jobs},\{summary.machines},\{summary.operations},\{summary.repeats},\{summary.makespan},\{summary.tardiness},\{summary.score},\{summary.checksum}\n"
  }
  result
}
