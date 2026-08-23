///|
fn contains_signature(signatures : Array[String], signature : String) -> Bool {
  for value in signatures {
    if value == signature {
      return true
    }
  }
  false
}

///|
fn push_tabu(
  tabu : Array[String],
  signature : String,
  tenure : Int,
) -> Array[String] {
  let result = tabu.copy()
  result.push(signature)
  while result.length() > tenure && tenure > 0 {
    let _ = result.remove(0)
  }
  result
}

///|
pub fn tabu_search(
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
  let mut current = base
  let mut best = base
  let mut tabu : Array[String] = []
  let history : Array[Int] = [best.score]
  for iteration in 0..<config.iterations {
    let mut selected : SearchSnapshot? = None
    let mut selected_score = 1_000_000_000
    let neighborhood = if config.neighborhood_size < input.jobs.length() {
      config.neighborhood_size
    } else {
      input.jobs.length()
    }
    for offset in 1..<=neighborhood {
      let left = iteration % input.jobs.length()
      let right = (left + offset) % input.jobs.length()
      match candidate_from_pair(input, options, weights, left, right) {
        Some(candidate) => {
          let signature = candidate.schedule.signature()
          let aspirational = candidate.evaluation.better_than(best.evaluation)
          if (aspirational || !contains_signature(tabu, signature)) &&
            candidate.score < selected_score {
            selected = Some(candidate)
            selected_score = candidate.score
          }
        }
        None => ()
      }
    }
    match selected {
      Some(candidate) => {
        current = candidate
        if current.evaluation.better_than(best.evaluation) {
          best = current
        }
        tabu = push_tabu(tabu, current.schedule.signature(), config.tabu_tenure)
      }
      None => ()
    }
    history.push(best.score + current.score - current.score)
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
