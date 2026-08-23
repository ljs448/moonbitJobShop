///|
pub struct PolicyComparison {
  name : String
  score : Int
  makespan : Int
  tardiness : Int
  feasible : Bool
  rank : Int
} derive(Eq, Debug)

///|
pub fn dispatch_policy_matrix(
  input : ScheduleInput,
) -> Result[Array[PolicyResult], String] {
  compare_policies(input, default_policies())
}

///|
pub fn policy_comparisons(
  results : Array[PolicyResult],
) -> Array[PolicyComparison] {
  let result : Array[PolicyComparison] = []
  for item in results {
    result.push({
      name: item.policy.name,
      score: item.evaluation.score,
      makespan: item.evaluation.makespan,
      tardiness: item.evaluation.tardiness,
      feasible: item.evaluation.feasible,
      rank: 0,
    })
  }
  for index in 0..<result.length() {
    let mut rank = 1
    for other in result {
      if other.score < result[index].score {
        rank += 1
      }
    }
    let current = result[index]
    result[index] = { ..current, rank, }
  }
  result
}

///|
pub fn policy_quality_table(results : Array[PolicyResult]) -> String {
  let comparisons = policy_comparisons(results)
  let mut text = "policy,score,makespan,tardiness,feasible,rank\n"
  for item in comparisons {
    text += "\{item.name},\{item.score},\{item.makespan},\{item.tardiness},\{item.feasible},\{item.rank}\n"
  }
  text
}

///|
pub fn best_policy_name(results : Array[PolicyResult]) -> String {
  match best_policy(results) {
    Some(result) => result.policy.name
    None => ""
  }
}

///|
pub fn policy_score_gap(results : Array[PolicyResult]) -> Int {
  if results.length() < 2 {
    return 0
  }
  let mut minimum = results[0].evaluation.score
  let mut maximum = minimum
  for result in results[1:] {
    if result.evaluation.score < minimum {
      minimum = result.evaluation.score
    }
    if result.evaluation.score > maximum {
      maximum = result.evaluation.score
    }
  }
  maximum - minimum
}

///|
pub fn policy_names(results : Array[PolicyResult]) -> Array[String] {
  let result : Array[String] = []
  for item in results {
    result.push(item.policy.name)
  }
  result
}

///|
pub fn policy_matrix_summary(results : Array[PolicyResult]) -> String {
  "policies=\{results.length()}, best=\{best_policy_name(results)}, score_gap=\{policy_score_gap(results)}"
}

///|
pub fn policy_is_better(left : PolicyResult, right : PolicyResult) -> Bool {
  left.evaluation.better_than(right.evaluation)
}
