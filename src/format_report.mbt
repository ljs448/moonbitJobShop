///|
fn section(title : String, body : String) -> String {
  "## " + title + "\n" + body + "\n"
}

///|
pub fn render_operational_report(
  schedule : Schedule,
  input : ScheduleInput,
  versions : Array[ScheduleVersion],
  calendars : Array[MachineCalendar],
) -> String {
  let projection = project_capacity(
    input,
    calendars,
    horizon=schedule.makespan(),
  )
  let constraints = validate_with_policy(
    schedule,
    input,
    ConstraintPolicy::default(),
    calendars,
  )
  let mut text = "# Job-shop operational report\n"
  text += section("schedule", render_schedule_text(schedule))
  text += section("capacity", capacity_projection_text(projection))
  text += section("constraints", constraint_report_text(constraints))
  text += section(
    "metrics",
    metrics_more_summary(schedule, input.jobs, input.machines),
  )
  text += section("routes", route_summary_table(input))
  text += section("versions", version_timeline(versions))
  text
}

///|
pub fn render_dashboard_report(
  schedule : Schedule,
  input : ScheduleInput,
) -> String {
  let dashboard = dashboard_metrics(schedule, input.jobs, input.machines)
  let bands = schedule_load_bands(schedule, input.machines)
  section("dashboard", dashboard.summary()) +
  section("job metrics", job_metric_table(dashboard.jobs)) +
  section("load bands", load_band_table(bands)) +
  section(
    "lateness",
    lateness_bucket_table(lateness_buckets(schedule, input.jobs, 5)),
  )
}

///|
pub fn render_quality_report(
  schedule : Schedule,
  input : ScheduleInput,
  calendars : Array[MachineCalendar],
) -> String {
  let constraints = validate_with_policy(
    schedule,
    input,
    ConstraintPolicy::strict_due_dates(),
    calendars,
  )
  let mut text = "# Quality report\n"
  text += section("constraints", constraint_report_text(constraints))
  text += section(
    "missing operations",
    missing_operation_ids(schedule, input).join(","),
  )
  text += section(
    "schedule checks",
    "non_overlapping=\{schedule.is_non_overlapping()}, operation_count=\{schedule.operation_count()}, signature=\{schedule.signature()}",
  )
  text
}

///|
pub fn render_benchmark_dataset_report(
  dataset : BenchmarkDataset,
  summaries : Array[BenchmarkSummary],
) -> String {
  let mut text = "# Benchmark dataset report\n"
  text += section("dataset", dataset.describe())
  text += section("manifest", dataset.manifest())
  text += section("results", dataset_result_table(dataset, summaries))
  text += section("checksum", dataset_checksum(summaries))
  text
}

///|
pub fn render_search_batch_report(batch : SearchBatchResult) -> String {
  section("search portfolio", batch.summary()) +
  search_trace_table(batch.traces)
}

///|
pub fn report_line_count(report : String) -> Int {
  report.split("\n").length()
}

///|
pub fn compact_report(report : String, maximum_lines : Int) -> String {
  if maximum_lines <= 0 {
    return ""
  }
  let mut result = ""
  let mut index = 0
  for line in report.split("\n") {
    if index >= maximum_lines {
      break
    }
    if index > 0 {
      result += "\n"
    }
    result += "\{line}"
    index += 1
  }
  result
}
