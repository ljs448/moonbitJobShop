///|
pub struct BoundaryCase {
  name : String
  input : ScheduleInput
  expected_valid : Bool
} derive(Eq, Debug)

///|
pub struct BoundaryResult {
  name : String
  valid : Bool
  dispatchable : Bool
  message : String
  deterministic : Bool
} derive(Eq, Debug)

///|
fn empty_input() -> ScheduleInput {
  ScheduleInput::new(jobs=[], machines=[], setup_times=[])
}

///|
fn single_machine_case() -> ScheduleInput {
  benchmark_case(jobs=1, machines=1, operations_per_job=1).input
}

///|
fn zero_operation_case() -> ScheduleInput {
  ScheduleInput::new(
    jobs=[Job::new(id="empty", name="Empty", due_time=1, operations=[])],
    machines=[Machine::new(id="m", name="Machine")],
    setup_times=[],
  )
}

///|
fn negative_duration_case() -> ScheduleInput {
  ScheduleInput::new(
    jobs=[
      Job::new(id="negative", name="Negative", due_time=1, operations=[
        Operation::new(
          id="op",
          name="Operation",
          duration=-1,
          machine_ids=["m"],
          setup_group="g",
        ),
      ]),
    ],
    machines=[Machine::new(id="m", name="Machine")],
    setup_times=[],
  )
}

///|
pub fn boundary_cases() -> Array[BoundaryCase] {
  [
    { name: "empty", input: empty_input(), expected_valid: false },
    {
      name: "single-machine",
      input: single_machine_case(),
      expected_valid: true,
    },
    {
      name: "zero-operation",
      input: zero_operation_case(),
      expected_valid: false,
    },
    {
      name: "negative-duration",
      input: negative_duration_case(),
      expected_valid: false,
    },
  ]
}

///|
fn validation_message(input : ScheduleInput) -> String {
  match input.validate() {
    Some(message) => message
    None => "ok"
  }
}

///|
pub fn run_boundary_checks() -> Array[BoundaryResult] {
  let result : Array[BoundaryResult] = []
  for boundary in boundary_cases() {
    let valid = boundary.input.validate() is None
    let dispatchable = match dispatch(boundary.input) {
      Ok(_) => true
      Err(_) => false
    }
    let deterministic = match
      (dispatch(boundary.input), dispatch(boundary.input)) {
      (Ok(left), Ok(right)) => left.signature() == right.signature()
      (Err(left), Err(right)) => left == right
      _ => false
    }
    result.push({
      name: boundary.name,
      valid,
      dispatchable,
      message: validation_message(boundary.input),
      deterministic,
    })
  }
  result
}

///|
pub fn boundary_result_table(results : Array[BoundaryResult]) -> String {
  let mut text = "case,valid,dispatchable,deterministic,message\n"
  for result in results {
    text += "\{result.name},\{result.valid},\{result.dispatchable},\{result.deterministic},\{result.message}\n"
  }
  text
}

///|
pub fn boundary_summary(results : Array[BoundaryResult]) -> String {
  let mut passed = 0
  for result in results {
    if result.deterministic {
      passed += 1
    }
  }
  "cases=\{results.length()}, deterministic=\{passed}"
}

///|
pub struct DispatchTrial {
  name : String
  schedule : Schedule
  score : Int
  makespan : Int
  feasible : Bool
} derive(Eq, Debug)

///|
pub fn dispatch_trials(
  input : ScheduleInput,
  options : Array[(String, DispatchOptions)],
) -> Result[Array[DispatchTrial], String] {
  let result : Array[DispatchTrial] = []
  for item in options {
    let (name, config) = item
    match dispatch_with_options(input, config) {
      Ok(schedule) => {
        let evaluation = evaluate(schedule, input, ObjectiveWeights::balanced())
        result.push({
          name,
          schedule,
          score: evaluation.score,
          makespan: evaluation.makespan,
          feasible: evaluation.feasible,
        })
      }
      Err(message) => return Err(message)
    }
  }
  Ok(result)
}

///|
pub fn trial_table(trials : Array[DispatchTrial]) -> String {
  let mut text = "trial,score,makespan,feasible,checksum\n"
  for trial in trials {
    text += "\{trial.name},\{trial.score},\{trial.makespan},\{trial.feasible},\{trial.schedule.signature()}\n"
  }
  text
}

///|
pub fn robustness_signature(results : Array[BoundaryResult]) -> String {
  let mut text = ""
  for result in results {
    text += "\{result.name}:\{result.valid}:\{result.deterministic};"
  }
  text
}
