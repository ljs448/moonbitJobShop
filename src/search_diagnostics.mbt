///|
pub struct SearchDiagnostic {
  algorithm : String
  iterations : Int
  baseline_score : Int
  final_score : Int
  improvement : Int
  history_points : Int
  monotonic : Bool
} derive(Eq, Debug)

///|
pub fn history_is_nonincreasing(history : Array[Int]) -> Bool {
  for index in 1..<history.length() {
    if history[index] > history[index - 1] {
      return false
    }
  }
  true
}

///|
pub fn history_min(history : Array[Int]) -> Int {
  if history.length() == 0 {
    return 0
  }
  let mut minimum = history[0]
  for value in history[1:] {
    if value < minimum {
      minimum = value
    }
  }
  minimum
}

///|
pub fn history_max(history : Array[Int]) -> Int {
  if history.length() == 0 {
    return 0
  }
  let mut maximum = history[0]
  for value in history[1:] {
    if value > maximum {
      maximum = value
    }
  }
  maximum
}

///|
pub fn search_diagnostic(
  algorithm : String,
  result : SearchResult,
) -> SearchDiagnostic {
  {
    algorithm,
    iterations: result.iterations,
    baseline_score: result.baseline.score,
    final_score: result.evaluation.score,
    improvement: result.baseline.score - result.evaluation.score,
    history_points: result.history.length(),
    monotonic: history_is_nonincreasing(result.history),
  }
}

///|
pub fn search_diagnostic_text(diagnostic : SearchDiagnostic) -> String {
  "algorithm=\{diagnostic.algorithm}, iterations=\{diagnostic.iterations}, baseline=\{diagnostic.baseline_score}, final=\{diagnostic.final_score}, improvement=\{diagnostic.improvement}, history=\{diagnostic.history_points}, monotonic=\{diagnostic.monotonic}"
}

///|
pub fn search_history_table(result : SearchResult) -> String {
  let mut text = "iteration,score\n"
  for index, score in result.history {
    text += "\{index},\{score}\n"
  }
  text
}

///|
pub fn search_result_summary(
  algorithm : String,
  result : SearchResult,
) -> String {
  search_diagnostic_text(search_diagnostic(algorithm, result)) +
  ", checksum=" +
  result.checksum
}

///|
pub fn search_improvement_percent(result : SearchResult) -> Int {
  if result.baseline.score == 0 {
    0
  } else {
    (result.baseline.score - result.evaluation.score) *
    100 /
    result.baseline.score
  }
}

///|
pub fn search_is_feasible(result : SearchResult) -> Bool {
  result.evaluation.feasible
}
