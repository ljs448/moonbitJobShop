///|
pub struct SearchConfig {
  iterations : Int
  seed : Int
  population_size : Int
  neighborhood_size : Int
  tabu_tenure : Int
  temperature : Int
} derive(Eq, Debug)

///|
pub fn SearchConfig::new(iterations~ : Int, seed~ : Int) -> SearchConfig {
  {
    iterations,
    seed,
    population_size: 6,
    neighborhood_size: 8,
    tabu_tenure: 4,
    temperature: 10,
  }
}

///|
pub fn SearchConfig::with_population_size(
  self : SearchConfig,
  population_size : Int,
) -> SearchConfig {
  { ..self, population_size, }
}

///|
pub fn SearchConfig::with_neighborhood_size(
  self : SearchConfig,
  neighborhood_size : Int,
) -> SearchConfig {
  { ..self, neighborhood_size, }
}

///|
pub fn SearchConfig::with_tabu_tenure(
  self : SearchConfig,
  tabu_tenure : Int,
) -> SearchConfig {
  { ..self, tabu_tenure, }
}

///|
pub fn SearchConfig::with_temperature(
  self : SearchConfig,
  temperature : Int,
) -> SearchConfig {
  { ..self, temperature, }
}

///|
pub fn SearchConfig::validate(self : SearchConfig) -> String? {
  if self.iterations < 0 {
    return Some("search iterations cannot be negative")
  }
  if self.population_size <= 0 {
    return Some("population size must be positive")
  }
  if self.neighborhood_size <= 0 {
    return Some("neighborhood size must be positive")
  }
  if self.tabu_tenure < 0 {
    return Some("tabu tenure cannot be negative")
  }
  if self.temperature < 0 {
    return Some("temperature cannot be negative")
  }
  None
}

///|
pub struct SearchSnapshot {
  schedule : Schedule
  evaluation : Evaluation
  score : Int
} derive(Eq, Debug)

///|
fn snapshot(schedule : Schedule, evaluation : Evaluation) -> SearchSnapshot {
  { schedule, evaluation, score: evaluation.score }
}

///|
pub struct SearchResult {
  schedule : Schedule
  baseline : SearchSnapshot
  evaluation : Evaluation
  history : Array[Int]
  population_history : Array[Int]
  checksum : String
  iterations : Int
} derive(Eq, Debug)

///|
fn make_search_result(
  schedule : Schedule,
  baseline : SearchSnapshot,
  evaluation : Evaluation,
  history : Array[Int],
  population_history : Array[Int],
  iterations : Int,
) -> SearchResult {
  {
    schedule,
    baseline,
    evaluation,
    history,
    population_history,
    checksum: schedule.signature(),
    iterations,
  }
}
