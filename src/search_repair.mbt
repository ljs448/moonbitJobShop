///|
pub struct RepairResult {
  schedule : Schedule
  evaluation : Evaluation
  repaired : Bool
  reason : String
} derive(Eq, Debug)

///|
pub fn repair_schedule(
  schedule : Schedule,
  input : ScheduleInput,
  options : DispatchOptions,
) -> Result[RepairResult, String] {
  let current = evaluate(schedule, input, ObjectiveWeights::balanced())
  if current.feasible {
    return Ok({
      schedule,
      evaluation: current,
      repaired: false,
      reason: "already feasible",
    })
  }
  match dispatch_with_options(input, options) {
    Ok(repaired) =>
      Ok({
        schedule: repaired,
        evaluation: evaluate(repaired, input, ObjectiveWeights::balanced()),
        repaired: true,
        reason: "rebuilt with deterministic dispatch",
      })
    Err(message) => Err(message)
  }
}

///|
pub struct RuinConfig {
  remove_count : Int
  iterations : Int
  seed : Int
} derive(Eq, Debug)

///|
pub fn RuinConfig::new(
  remove_count~ : Int,
  iterations~ : Int,
  seed~ : Int,
) -> RuinConfig {
  { remove_count, iterations, seed }
}

///|
pub fn RuinConfig::validate(self : RuinConfig) -> String? {
  if self.remove_count < 0 || self.iterations < 0 {
    Some("ruin parameters cannot be negative")
  } else {
    None
  }
}

///|
fn ruin_jobs(
  jobs : Array[Job],
  remove_count : Int,
  rng : DeterministicRng,
) -> (Array[Job], DeterministicRng) {
  let result = jobs.copy()
  let mut current_rng = rng
  let count = if remove_count > result.length() {
    result.length()
  } else {
    remove_count
  }
  for _ in 0..<count {
    let (next, index) = current_rng.next_bounded(result.length())
    current_rng = next
    if result.length() > 0 {
      let _ = result.remove(index)
    }
  }
  (result, current_rng)
}

///|
pub fn ruin_and_recreate(
  input : ScheduleInput,
  options : DispatchOptions,
  config : RuinConfig,
) -> Result[SearchResult, String] {
  match config.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  let weights = ObjectiveWeights::balanced()
  let base = match baseline_search(input, options, weights) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let mut best = base
  let mut rng = DeterministicRng::new(config.seed)
  let history : Array[Int] = [best.score]
  for iteration in 0..<config.iterations {
    let (ruined, next_rng) = ruin_jobs(input.jobs, config.remove_count, rng)
    rng = next_rng
    let recreated = ruined
    let missing : Array[Job] = []
    for job in input.jobs {
      if !recreated.contains(job) {
        missing.push(job)
      }
    }
    for job in missing {
      recreated.push(job)
    }
    match dispatch_candidate(input, recreated, options) {
      Ok(schedule) => {
        let candidate = evaluate(schedule, input, weights)
        if candidate.better_than(best.evaluation) {
          best = snapshot(schedule, candidate)
        }
      }
      Err(_) => ()
    }
    history.push(best.score + iteration - iteration)
  }
  Ok(
    make_search_result(
      best.schedule,
      base,
      best.evaluation,
      history,
      [],
      config.iterations,
    ),
  )
}

///|
pub struct SearchTrace {
  algorithm : String
  before_score : Int
  after_score : Int
  iterations : Int
  accepted : Int
} derive(Eq, Debug)

///|
pub fn trace_search(algorithm : String, result : SearchResult) -> SearchTrace {
  let mut accepted = 0
  for index in 1..<result.history.length() {
    if result.history[index] < result.history[index - 1] {
      accepted += 1
    }
  }
  {
    algorithm,
    before_score: result.baseline.score,
    after_score: result.evaluation.score,
    iterations: result.iterations,
    accepted,
  }
}

///|
pub fn SearchTrace::summary(self : SearchTrace) -> String {
  "algorithm=\{self.algorithm}, before=\{self.before_score}, after=\{self.after_score}, iterations=\{self.iterations}, accepted=\{self.accepted}"
}
