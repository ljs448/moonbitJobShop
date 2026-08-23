///|
pub struct SearchPortfolio {
  local_enabled : Bool
  tabu : Bool
  genetic : Bool
  annealing : Bool
  ruin : Bool
  iterations : Int
  seed : Int
} derive(Eq, Debug)

///|
pub fn SearchPortfolio::small(seed~ : Int) -> SearchPortfolio {
  {
    local_enabled: true,
    tabu: true,
    genetic: true,
    annealing: true,
    ruin: true,
    iterations: 4,
    seed,
  }
}

///|
pub fn SearchPortfolio::baseline(seed~ : Int) -> SearchPortfolio {
  {
    local_enabled: true,
    tabu: false,
    genetic: false,
    annealing: false,
    ruin: false,
    iterations: 0,
    seed,
  }
}

///|
pub fn SearchPortfolio::with_iterations(
  self : SearchPortfolio,
  iterations : Int,
) -> SearchPortfolio {
  { ..self, iterations: if iterations < 0 { 0 } else { iterations } }
}

///|
pub struct SearchBatchResult {
  best : SearchResult
  traces : Array[SearchTrace]
  completed : Int
} derive(Eq, Debug)

///|
fn consider_search(
  current : SearchResult?,
  candidate : SearchResult,
) -> SearchResult {
  match current {
    Some(best) =>
      if candidate.evaluation.better_than(best.evaluation) {
        candidate
      } else {
        best
      }
    None => candidate
  }
}

///|
pub fn search_portfolio(
  input : ScheduleInput,
  options : DispatchOptions,
  portfolio : SearchPortfolio,
) -> Result[SearchBatchResult, String] {
  let mut best : SearchResult? = None
  let traces : Array[SearchTrace] = []
  let mut completed = 0
  let base_config = SearchConfig::new(
    iterations=portfolio.iterations,
    seed=portfolio.seed,
  )
  if portfolio.local_enabled {
    match local_search(input, options, base_config) {
      Ok(result) => {
        traces.push(trace_search("local", result))
        best = Some(consider_search(best, result))
        completed += 1
      }
      Err(_) => ()
    }
  }
  if portfolio.tabu {
    match tabu_search(input, options, base_config) {
      Ok(result) => {
        traces.push(trace_search("tabu", result))
        best = Some(consider_search(best, result))
        completed += 1
      }
      Err(_) => ()
    }
  }
  if portfolio.genetic {
    let config = base_config.with_population_size(3)
    match genetic_search(input, options, config) {
      Ok(result) => {
        traces.push(trace_search("genetic", result))
        best = Some(consider_search(best, result))
        completed += 1
      }
      Err(_) => ()
    }
  }
  if portfolio.annealing {
    let config = AnnealingConfig::new(
      iterations=portfolio.iterations,
      seed=portfolio.seed,
    )
    match anneal_search(input, options, config) {
      Ok(result) => {
        traces.push(trace_search("annealing", result))
        best = Some(consider_search(best, result))
        completed += 1
      }
      Err(_) => ()
    }
  }
  if portfolio.ruin {
    let config = RuinConfig::new(
      remove_count=1,
      iterations=portfolio.iterations,
      seed=portfolio.seed,
    )
    match ruin_and_recreate(input, options, config) {
      Ok(result) => {
        traces.push(trace_search("ruin-recreate", result))
        best = Some(consider_search(best, result))
        completed += 1
      }
      Err(_) => ()
    }
  }
  match best {
    Some(result) => Ok({ best: result, traces, completed })
    None => Err("search portfolio completed no algorithms")
  }
}

///|
pub fn SearchBatchResult::summary(self : SearchBatchResult) -> String {
  "algorithms=\{self.completed}, traces=\{self.traces.length()}, best_score=\{self.best.evaluation.score}, makespan=\{self.best.schedule.makespan()}"
}

///|
pub fn search_trace_table(traces : Array[SearchTrace]) -> String {
  let mut text = "algorithm,before,after,iterations,accepted\n"
  for trace in traces {
    text += "\{trace.algorithm},\{trace.before_score},\{trace.after_score},\{trace.iterations},\{trace.accepted}\n"
  }
  text
}

///|
pub fn search_portfolio_names(portfolio : SearchPortfolio) -> Array[String] {
  let result : Array[String] = []
  if portfolio.local_enabled {
    result.push("local")
  }
  if portfolio.tabu {
    result.push("tabu")
  }
  if portfolio.genetic {
    result.push("genetic")
  }
  if portfolio.annealing {
    result.push("annealing")
  }
  if portfolio.ruin {
    result.push("ruin-recreate")
  }
  result
}
