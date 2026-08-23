///|
pub struct ScheduleVersion {
  version : Int
  parent_signature : String
  schedule : Schedule
  diff : ScheduleDiff
  applied_events : Int
  labels : Array[String]
} derive(Eq, Debug)

///|
pub fn ScheduleVersion::summary(self : ScheduleVersion) -> String {
  "version=\{self.version}, events=\{self.applied_events}, operations=\{self.schedule.operation_count()}, changes=\{self.diff.change_count()}"
}

///|
pub fn replay_events(
  input : ScheduleInput,
  batches : Array[Array[ScheduleEvent]],
  options : RescheduleOptions,
) -> Result[Array[ScheduleVersion], String] {
  let initial = match dispatch(input) {
    Ok(schedule) => schedule
    Err(message) => return Err(message)
  }
  let versions : Array[ScheduleVersion] = []
  let mut current_input = input
  let mut current_schedule = initial
  for index, batch in batches {
    match reschedule(current_input, batch, options) {
      Ok(result) => {
        let diff = diff_schedules(current_schedule, result.schedule)
        let labels : Array[String] = []
        for event in batch {
          labels.push(event.label())
        }
        versions.push({
          version: index + 1,
          parent_signature: current_schedule.signature(),
          schedule: result.schedule,
          diff,
          applied_events: result.applied_events,
          labels,
        })
        current_input = result.input
        current_schedule = result.schedule
      }
      Err(message) => return Err(message)
    }
  }
  Ok(versions)
}

///|
pub fn version_signatures(versions : Array[ScheduleVersion]) -> Array[String] {
  let result : Array[String] = []
  for version in versions {
    result.push(version.schedule.signature())
  }
  result
}

///|
pub fn version_timeline(versions : Array[ScheduleVersion]) -> String {
  let mut text = "version,events,changes,signature\n"
  for version in versions {
    text += "\{version.version},\{version.applied_events},\{version.diff.change_count()},\{version.schedule.signature()}\n"
  }
  text
}

///|
pub fn replay_event_labels(
  batches : Array[Array[ScheduleEvent]],
) -> Array[String] {
  let result : Array[String] = []
  for batch in batches {
    for event in batch {
      result.push(event.label())
    }
  }
  result
}

///|
pub fn deduplicate_events(
  events : Array[ScheduleEvent],
) -> Array[ScheduleEvent] {
  let result : Array[ScheduleEvent] = []
  let labels : Array[String] = []
  for event in events {
    let label = event.label()
    if !labels.contains(label) {
      labels.push(label)
      result.push(event)
    }
  }
  result
}
