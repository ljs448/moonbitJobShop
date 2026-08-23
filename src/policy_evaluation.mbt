///|
pub struct DispatchPolicy {
  name : String
  rule : DispatchRule
  setup_weight : Int
  due_weight : Int
  lookahead : Int
} derive(Eq, Debug)

///|
pub fn DispatchPolicy::new(
  name~ : String,
  rule~ : DispatchRule,
) -> DispatchPolicy {
  { name, rule, setup_weight: 1, due_weight: 1, lookahead: 1 }
}

///|
pub fn DispatchPolicy::with_weights(
  self : DispatchPolicy,
  setup_weight : Int,
  due_weight : Int,
) -> DispatchPolicy {
  {
    ..self,
    setup_weight: if setup_weight < 0 {
      0
    } else {
      setup_weight
    },
    due_weight: if due_weight < 0 {
      0
    } else {
      due_weight
    },
  }
}

///|
pub fn DispatchPolicy::with_lookahead(
  self : DispatchPolicy,
  lookahead : Int,
) -> DispatchPolicy {
  { ..self, lookahead: if lookahead < 1 { 1 } else { lookahead } }
}

///|
pub fn DispatchPolicy::validate(self : DispatchPolicy) -> String? {
  if self.name == "" {
    return Some("policy name cannot be empty")
  }
  if self.setup_weight < 0 || self.due_weight < 0 {
    return Some("policy weights cannot be negative")
  }
  if self.lookahead <= 0 {
    Some("policy lookahead must be positive")
  } else {
    None
  }
}

///|
pub fn DispatchPolicy::description(self : DispatchPolicy) -> String {
  "name=\{self.name}, rule=\{self.rule.code}, setup_weight=\{self.setup_weight}, due_weight=\{self.due_weight}, lookahead=\{self.lookahead}"
}

///|
pub fn default_policies() -> Array[DispatchPolicy] {
  [
    DispatchPolicy::new(name="fifo", rule=DispatchRule::fifo()),
    DispatchPolicy::new(
      name="shortest",
      rule=DispatchRule::shortest_processing_time(),
    ),
    DispatchPolicy::new(name="due-date", rule=DispatchRule::earliest_due_date()),
    DispatchPolicy::new(name="slack", rule=DispatchRule::least_slack()),
    DispatchPolicy::new(name="setup-aware", rule=DispatchRule::setup_aware()),
  ]
}

///|
pub struct PolicyResult {
  policy : DispatchPolicy
  schedule : Schedule
  evaluation : Evaluation
} derive(Eq, Debug)

///|
pub fn dispatch_with_policy(
  input : ScheduleInput,
  policy : DispatchPolicy,
) -> Result[PolicyResult, String] {
  match policy.validate() {
    Some(message) => return Err(message)
    None => ()
  }
  let options = DispatchOptions::default()
    .with_rule(policy.rule)
    .with_setup_penalty(policy.setup_weight)
  match dispatch_with_options(input, options) {
    Ok(schedule) =>
      Ok({
        policy,
        schedule,
        evaluation: evaluate(schedule, input, ObjectiveWeights::balanced()),
      })
    Err(message) => Err(message)
  }
}

///|
pub fn compare_policies(
  input : ScheduleInput,
  policies : Array[DispatchPolicy],
) -> Result[Array[PolicyResult], String] {
  let result : Array[PolicyResult] = []
  for policy in policies {
    match dispatch_with_policy(input, policy) {
      Ok(value) => result.push(value)
      Err(message) => return Err(message)
    }
  }
  Ok(result)
}

///|
pub fn best_policy(results : Array[PolicyResult]) -> PolicyResult? {
  if results.length() == 0 {
    return None
  }
  let mut best = results[0]
  for result in results[1:] {
    if result.evaluation.better_than(best.evaluation) {
      best = result
    }
  }
  Some(best)
}

///|
pub fn policy_score_table(results : Array[PolicyResult]) -> String {
  let mut text = "policy,score,makespan,tardiness,feasible\n"
  for result in results {
    text += "\{result.policy.name},\{result.evaluation.score},\{result.evaluation.makespan},\{result.evaluation.tardiness},\{result.evaluation.feasible}\n"
  }
  text
}
