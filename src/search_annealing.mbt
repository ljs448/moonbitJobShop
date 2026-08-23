///|
pub struct AnnealingConfig {
  iterations : Int
  seed : Int
  initial_temperature : Int
  cooling_numerator : Int
  cooling_denominator : Int
  neighborhood_limit : Int
} derive(Eq, Debug)

///|
pub fn AnnealingConfig::new(iterations~ : Int, seed~ : Int) -> AnnealingConfig {
  {
    iterations,
    seed,
    initial_temperature: 12,
    cooling_numerator: 9,
    cooling_denominator: 10,
    neighborhood_limit: 12,
  }
}

///|
pub fn AnnealingConfig::with_temperature(
  self : AnnealingConfig,
  temperature : Int,
) -> AnnealingConfig {
  { ..self, initial_temperature: temperature }
}

///|
pub fn AnnealingConfig::with_cooling(
  self : AnnealingConfig,
  numerator : Int,
  denominator : Int,
) -> AnnealingConfig {
  { ..self, cooling_numerator: numerator, cooling_denominator: denominator }
}

///|
pub fn AnnealingConfig::with_neighborhood_limit(
  self : AnnealingConfig,
  limit : Int,
) -> AnnealingConfig {
  { ..self, neighborhood_limit: limit }
}

///|
pub fn AnnealingConfig::validate(self : AnnealingConfig) -> String? {
  if self.iterations < 0 {
    return Some("annealing iterations cannot be negative")
  }
  if self.initial_temperature < 0 {
    return Some("annealing temperature cannot be negative")
  }
  if self.cooling_numerator < 0 || self.cooling_denominator <= 0 {
    return Some("annealing cooling ratio is invalid")
  }
  if self.neighborhood_limit <= 0 {
    return Some("annealing neighborhood limit must be positive")
  }
  None
}

///|
fn annealing_candidate(
  input : ScheduleInput,
  options : DispatchOptions,
  weights : ObjectiveWeights,
  jobs : Array[Job],
) -> SearchSnapshot? {
  match dispatch_candidate(input, jobs, options) {
    Ok(schedule) => Some(snapshot(schedule, evaluate(schedule, input, weights)))
    Err(_) => None
  }
}

///|
pub fn anneal_search(
  input : ScheduleInput,
  options : DispatchOptions,
  config : AnnealingConfig,
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
  if config.iterations == 0 || input.jobs.length() < 2 {
    return Ok(
      make_search_result(
        base.schedule,
        base,
        base.evaluation,
        [base.score],
        [],
        0,
      ),
    )
  }
  let mut current = base
  let mut best = base
  let mut temperature = config.initial_temperature
  let mut rng = DeterministicRng::new(config.seed)
  let history : Array[Int] = [best.score]
  for iteration in 0..<config.iterations {
    let kind = NeighborhoodKind::all()[iteration % 3]
    let neighbors = generate_job_neighbors(
      input.jobs,
      kind,
      limit=config.neighborhood_limit,
    )
    if neighbors.length() > 0 {
      let (next_rng, index) = rng.next_bounded(neighbors.length())
      rng = next_rng
      match annealing_candidate(input, options, weights, neighbors[index]) {
        Some(candidate) => {
          let improvement = candidate.score <= current.score
          let tolerance = if temperature < 0 { 0 } else { temperature }
          if improvement || candidate.score <= current.score + tolerance {
            current = candidate
          }
          if candidate.evaluation.better_than(best.evaluation) {
            best = candidate
          }
        }
        None => ()
      }
    }
    history.push(best.score)
    temperature = temperature *
      config.cooling_numerator /
      config.cooling_denominator
    if temperature < 0 {
      temperature = 0
    }
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
