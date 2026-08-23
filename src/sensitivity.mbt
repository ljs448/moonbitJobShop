///|
pub struct SensitivityPoint {
  frozen_until : Int
  schedule : Schedule
  makespan : Int
  tardiness : Int
  score : Int
  feasible : Bool
} derive(Eq, Debug)

///|
pub struct SensitivityReport {
  points : Array[SensitivityPoint]
  baseline_score : Int
  best_frozen_until : Int
  best_score : Int
} derive(Eq, Debug)

///|
pub fn dispatch_sensitivity(
  input : ScheduleInput,
  frozen_untils : Array[Int],
) -> Result[SensitivityReport, String] {
  if frozen_untils.length() == 0 {
    return Err("sensitivity needs at least one point")
  }
  let baseline = match dispatch(input) {
    Ok(schedule) => evaluate(schedule, input, ObjectiveWeights::balanced())
    Err(message) => return Err(message)
  }
  let points : Array[SensitivityPoint] = []
  for requested in frozen_untils {
    let frozen = if requested < 0 { 0 } else { requested }
    let options = DispatchOptions::default().with_frozen_until(frozen)
    match dispatch_with_options(input, options) {
      Ok(schedule) => {
        let evaluation = evaluate(schedule, input, ObjectiveWeights::balanced())
        points.push({
          frozen_until: frozen,
          schedule,
          makespan: evaluation.makespan,
          tardiness: evaluation.tardiness,
          score: evaluation.score,
          feasible: evaluation.feasible,
        })
      }
      Err(message) => return Err(message)
    }
  }
  let mut best_frozen = points[0].frozen_until
  let mut best_score = points[0].score
  for point in points[1:] {
    if point.score < best_score {
      best_score = point.score
      best_frozen = point.frozen_until
    }
  }
  Ok({
    points,
    baseline_score: baseline.score,
    best_frozen_until: best_frozen,
    best_score,
  })
}

///|
pub fn sensitivity_summary(report : SensitivityReport) -> String {
  "points=\{report.points.length()}, baseline=\{report.baseline_score}, best=\{report.best_score}, best_frozen_until=\{report.best_frozen_until}"
}

///|
pub fn sensitivity_table(report : SensitivityReport) -> String {
  let mut text = "frozen_until,makespan,tardiness,score,feasible,checksum\n"
  for point in report.points {
    text += "\{point.frozen_until},\{point.makespan},\{point.tardiness},\{point.score},\{point.feasible},\{point.schedule.signature()}\n"
  }
  text
}

///|
pub fn sensitivity_best(report : SensitivityReport) -> SensitivityPoint? {
  if report.points.length() == 0 {
    return None
  }
  for point in report.points {
    if point.frozen_until == report.best_frozen_until &&
      point.score == report.best_score {
      return Some(point)
    }
  }
  None
}

///|
pub fn sensitivity_score_range(report : SensitivityReport) -> Int {
  if report.points.length() == 0 {
    return 0
  }
  let mut minimum = report.points[0].score
  let mut maximum = minimum
  for point in report.points[1:] {
    if point.score < minimum {
      minimum = point.score
    }
    if point.score > maximum {
      maximum = point.score
    }
  }
  maximum - minimum
}

///|
pub fn sensitivity_checksum(report : SensitivityReport) -> String {
  let mut text = ""
  for point in report.points {
    text += "\{point.frozen_until}:\{point.schedule.signature()};"
  }
  text
}

///|
pub fn sensitivity_report(report : SensitivityReport) -> String {
  sensitivity_summary(report) + "\n" + sensitivity_table(report)
}
