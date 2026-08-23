///|
pub struct LookaheadScore {
  job_id : String
  operation_id : String
  machine_id : String
  due_pressure : Int
  setup_pressure : Int
  score : Int
} derive(Eq, Debug)

///|
fn lookahead_operation_score(
  job : Job,
  operation : Operation,
  options : DispatchOptions,
) -> LookaheadScore {
  let urgency = job.due_time - job.total_work()
  let due_pressure = if urgency < 0 { -urgency } else { 0 }
  let machine_id = operation.machine_ids[0]
  let mut setup_pressure = 0
  for calendar in options.calendars {
    if calendar.machine_id == machine_id {
      setup_pressure += calendar.blocked_time()
    }
  }
  let route_bonus = operation.route_width() * 2
  {
    job_id: job.id,
    operation_id: operation.id,
    machine_id,
    due_pressure,
    setup_pressure,
    score: due_pressure * 10 +
    operation.duration * 3 +
    setup_pressure -
    route_bonus,
  }
}

///|
fn lookahead_precedes(left : LookaheadScore, right : LookaheadScore) -> Bool {
  if left.score != right.score {
    left.score > right.score
  } else if left.due_pressure != right.due_pressure {
    left.due_pressure > right.due_pressure
  } else if left.job_id != right.job_id {
    left.job_id < right.job_id
  } else {
    left.operation_id < right.operation_id
  }
}

///|
pub fn rank_operations(
  input : ScheduleInput,
  options : DispatchOptions,
  limit : Int,
) -> Array[LookaheadScore] {
  let ranked : Array[LookaheadScore] = []
  for job in input.jobs {
    for operation in job.operations {
      let candidate = lookahead_operation_score(job, operation, options)
      let mut inserted = false
      for index in 0..<ranked.length() {
        if !inserted && lookahead_precedes(candidate, ranked[index]) {
          ranked.insert(index, candidate)
          inserted = true
          break
        }
      }
      if !inserted {
        ranked.push(candidate)
      }
    }
  }
  if limit <= 0 || ranked.length() <= limit {
    ranked
  } else {
    let result : Array[LookaheadScore] = []
    for index in 0..<limit {
      result.push(ranked[index])
    }
    result
  }
}

///|
fn ordered_jobs_for_lookahead(
  input : ScheduleInput,
  options : DispatchOptions,
  width : Int,
) -> Array[Job] {
  let ranked = rank_operations(input, options, input.operation_count())
  let result : Array[Job] = []
  for score in ranked {
    for job in input.jobs {
      if job.id == score.job_id && !result.contains(job) {
        result.push(job)
        break
      }
    }
    if width > 0 && result.length() >= width {
      break
    }
  }
  for job in input.jobs {
    if !result.contains(job) {
      result.push(job)
    }
  }
  result
}

///|
pub fn lookahead_schedule(
  input : ScheduleInput,
  options : DispatchOptions,
  width : Int,
) -> Result[Schedule, String] {
  if width < 0 {
    return Err("lookahead width cannot be negative")
  }
  let ordered = ordered_jobs_for_lookahead(input, options, width)
  dispatch_with_options({ ..input, jobs: ordered }, options)
}

///|
pub fn lookahead_score_table(scores : Array[LookaheadScore]) -> String {
  let mut text = "job,operation,machine,due_pressure,setup_pressure,score\n"
  for score in scores {
    text += "\{score.job_id},\{score.operation_id},\{score.machine_id},\{score.due_pressure},\{score.setup_pressure},\{score.score}\n"
  }
  text
}

///|
pub fn lookahead_summary(
  input : ScheduleInput,
  options : DispatchOptions,
  width : Int,
) -> String {
  let scores = rank_operations(input, options, width)
  "width=\{width}, candidates=\{scores.length()}, top_score=\{if scores.length() == 0 { 0 } else { scores[0].score }}"
}

///|
pub fn machine_choice_report(
  input : ScheduleInput,
  options : DispatchOptions,
) -> String {
  let _ = options
  let mut text = "job,operation,candidates\n"
  for job in input.jobs {
    for operation in job.operations {
      text += "\{job.id},\{operation.id},\{operation.machine_ids.length()}\n"
    }
  }
  text
}
