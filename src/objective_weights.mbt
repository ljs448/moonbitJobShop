///|
pub struct ObjectiveWeights {
  makespan : Int
  tardiness : Int
  load_balance : Int
  setup_count : Int
} derive(Eq, Debug)

///|
pub fn ObjectiveWeights::new(
  makespan~ : Int,
  tardiness~ : Int,
  load_balance~ : Int,
  setup_count~ : Int,
) -> ObjectiveWeights {
  { makespan, tardiness, load_balance, setup_count }
}

///|
pub fn ObjectiveWeights::balanced() -> ObjectiveWeights {
  ObjectiveWeights::new(makespan=4, tardiness=5, load_balance=2, setup_count=1)
}

///|
pub fn ObjectiveWeights::validate(self : ObjectiveWeights) -> String? {
  if self.makespan < 0 ||
    self.tardiness < 0 ||
    self.load_balance < 0 ||
    self.setup_count < 0 {
    Some("objective weights cannot be negative")
  } else if self.makespan +
    self.tardiness +
    self.load_balance +
    self.setup_count ==
    0 {
    Some("at least one objective weight must be positive")
  } else {
    None
  }
}

///|
pub struct Evaluation {
  score : Int
  makespan : Int
  tardiness : Int
  load_balance : Int
  setup_count : Int
  feasible : Bool
  violation : String?
} derive(Eq, Debug)

///|
fn scheduled_setup_count(schedule : Schedule) -> Int {
  total_setup_count(schedule)
}

///|
pub fn evaluate(
  schedule : Schedule,
  input : ScheduleInput,
  weights : ObjectiveWeights,
) -> Evaluation {
  let violation = validate_schedule(schedule, input)
  let feasible = violation is None
  if !feasible {
    return {
      score: 1_000_000_000,
      makespan: schedule.makespan(),
      tardiness: 1_000_000,
      load_balance: 1_000_000,
      setup_count: 1_000_000,
      feasible: false,
      violation,
    }
  }
  let makespan_value = makespan(schedule)
  let tardiness_value = total_tardiness(schedule, input.jobs)
  let balance_value = load_balance(schedule, input.machines)
  let setup_value = scheduled_setup_count(schedule)
  {
    score: makespan_value * weights.makespan +
    tardiness_value * weights.tardiness +
    balance_value * weights.load_balance +
    setup_value * weights.setup_count,
    makespan: makespan_value,
    tardiness: tardiness_value,
    load_balance: balance_value,
    setup_count: setup_value,
    feasible: true,
    violation: None,
  }
}

///|
pub fn Evaluation::better_than(self : Evaluation, other : Evaluation) -> Bool {
  if self.feasible != other.feasible {
    self.feasible
  } else {
    self.score < other.score
  }
}

///|
pub fn Evaluation::summary(self : Evaluation) -> String {
  let violation = match self.violation {
    Some(message) => message
    None => "none"
  }
  "score=\{self.score}, makespan=\{self.makespan}, tardiness=\{self.tardiness}, balance=\{self.load_balance}, setups=\{self.setup_count}, feasible=\{self.feasible}, violation=\{violation}"
}

///|
pub fn Evaluation::is_feasible(self : Evaluation) -> Bool {
  self.feasible
}
