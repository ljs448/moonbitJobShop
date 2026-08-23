///|
fn evaluate_jobs(
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
fn crossover_jobs(
  left : Array[Job],
  right : Array[Job],
  cut : Int,
) -> Array[Job] {
  let result : Array[Job] = []
  for i in 0..<left.length() {
    if i < cut {
      result.push(left[i])
    } else {
      let candidate = right[i]
      let mut duplicate = false
      for existing in result {
        if existing.id == candidate.id {
          duplicate = true
        }
      }
      if !duplicate {
        result.push(candidate)
      } else {
        for fallback in left {
          let mut present = false
          for existing in result {
            if existing.id == fallback.id {
              present = true
            }
          }
          if !present {
            result.push(fallback)
            break
          }
        }
      }
    }
  }
  result
}

///|
pub fn genetic_search(
  input : ScheduleInput,
  options : DispatchOptions,
  config : SearchConfig,
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
  let history : Array[Int] = [best.score]
  let population_history : Array[Int] = []
  let mut population : Array[SearchSnapshot] = [base]
  let mut rng = DeterministicRng::new(config.seed)
  let requested_population = if config.population_size < 1 {
    1
  } else {
    config.population_size
  }
  for generation in 0..<(config.iterations + 1) {
    let next_population : Array[SearchSnapshot] = []
    for population_index in 0..<requested_population {
      let (next_rng, offset) = rng.next_bounded(input.jobs.length())
      rng = next_rng
      let parent = population[population_index % population.length()]
      let rotated = rotate_jobs(
        input.jobs,
        offset + population_index + generation,
      )
      match evaluate_jobs(input, options, weights, rotated) {
        Some(candidate) => next_population.push(candidate)
        None => next_population.push(parent)
      }
    }
    if next_population.length() > 1 {
      let crossover = crossover_jobs(
        next_population[0].schedule.job_order(input.jobs),
        next_population[1].schedule.job_order(input.jobs),
        next_population.length() / 2,
      )
      match evaluate_jobs(input, options, weights, crossover) {
        Some(candidate) => next_population.push(candidate)
        None => ()
      }
    }
    population = next_population
    for candidate in population {
      if candidate.evaluation.better_than(best.evaluation) {
        best = candidate
      }
    }
    population_history.push(population.length())
    history.push(best.score)
  }
  Ok(
    make_search_result(
      best.schedule,
      base,
      best.evaluation,
      history,
      population_history,
      config.iterations,
    ),
  )
}
