///|
fn dispatch_candidate(
  input : ScheduleInput,
  jobs : Array[Job],
  options : DispatchOptions,
) -> Result[Schedule, String] {
  dispatch_with_options({ ..input, jobs, }, options)
}

///|
fn baseline_search(
  input : ScheduleInput,
  options : DispatchOptions,
  weights : ObjectiveWeights,
) -> Result[SearchSnapshot, String] {
  match dispatch_with_options(input, options) {
    Ok(schedule) => Ok(snapshot(schedule, evaluate(schedule, input, weights)))
    Err(message) => Err(message)
  }
}

///|
pub fn local_search(
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
  if input.jobs.length() < 2 || config.iterations == 0 {
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
  let mut best = base
  let history : Array[Int] = [best.score]
  let mut rng = DeterministicRng::new(config.seed)
  for iteration in 0..<config.iterations {
    let (next_rng, first) = rng.next_bounded(input.jobs.length())
    let (final_rng, offset) = next_rng.next_bounded(input.jobs.length() - 1)
    rng = final_rng
    let second = (first + offset + 1) % input.jobs.length()
    let jobs = swap_jobs(input.jobs, first, second)
    match dispatch_candidate(input, jobs, options) {
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
fn candidate_from_pair(
  input : ScheduleInput,
  options : DispatchOptions,
  weights : ObjectiveWeights,
  left : Int,
  right : Int,
) -> SearchSnapshot? {
  let jobs = swap_jobs(input.jobs, left, right)
  match dispatch_candidate(input, jobs, options) {
    Ok(schedule) => Some(snapshot(schedule, evaluate(schedule, input, weights)))
    Err(_) => None
  }
}
