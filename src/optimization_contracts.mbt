///|
pub struct ContractCheck {
  code : String
  passed : Bool
  details : String
} derive(Eq, Debug)

///|
fn contract(code : String, passed : Bool, details : String) -> ContractCheck {
  { code, passed, details }
}

///|
pub fn schedule_contracts(
  schedule : Schedule,
  input : ScheduleInput,
) -> Array[ContractCheck] {
  let result : Array[ContractCheck] = []
  let valid = validate_schedule(schedule, input) is None
  result.push(
    contract(
      "valid_schedule",
      valid,
      if valid {
        "all operations satisfy input constraints"
      } else {
        "schedule validation failed"
      },
    ),
  )
  let non_overlapping = schedule.is_non_overlapping()
  result.push(
    contract(
      "machine_non_overlap",
      non_overlapping,
      if non_overlapping {
        "machine intervals are disjoint"
      } else {
        "machine intervals overlap"
      },
    ),
  )
  let nonnegative = schedule.makespan() >= 0
  result.push(
    contract(
      "nonnegative_horizon",
      nonnegative,
      "makespan=\{schedule.makespan()}",
    ),
  )
  let complete = schedule.operation_count() == input.operation_count()
  result.push(
    contract(
      "operation_completeness",
      complete,
      "scheduled=\{schedule.operation_count()}, expected=\{input.operation_count()}",
    ),
  )
  result
}

///|
pub fn all_contracts_pass(checks : Array[ContractCheck]) -> Bool {
  for check in checks {
    if !check.passed {
      return false
    }
  }
  true
}

///|
pub fn contract_table(checks : Array[ContractCheck]) -> String {
  let mut text = "code,passed,details\n"
  for check in checks {
    text += "\{check.code},\{check.passed},\{check.details}\n"
  }
  text
}

///|
pub fn contract_summary(checks : Array[ContractCheck]) -> String {
  let mut passed = 0
  for check in checks {
    if check.passed {
      passed += 1
    }
  }
  "passed=\{passed}, total=\{checks.length()}, all=\{all_contracts_pass(checks)}"
}

///|
pub fn objective_contract(
  first : Evaluation,
  second : Evaluation,
) -> ContractCheck {
  let comparable = first.makespan >= 0 && second.makespan >= 0
  contract(
    "objective_nonnegative",
    comparable,
    "first=\{first.score}, second=\{second.score}",
  )
}

///|
pub fn input_contracts(input : ScheduleInput) -> Array[ContractCheck] {
  let result : Array[ContractCheck] = []
  let valid = input.validate() is None
  result.push(
    contract("valid_input", valid, if valid { "ok" } else { "invalid" }),
  )
  result.push(
    contract(
      "has_machine",
      input.machines.length() > 0,
      "machines=\{input.machines.length()}",
    ),
  )
  result.push(
    contract(
      "has_work",
      input.operation_count() > 0,
      "operations=\{input.operation_count()}",
    ),
  )
  result
}

///|
pub fn contract_report(schedule : Schedule, input : ScheduleInput) -> String {
  let checks = schedule_contracts(schedule, input)
  "# Contract report\n" +
  contract_summary(checks) +
  "\n" +
  contract_table(checks)
}

///|
pub fn contract_signature(checks : Array[ContractCheck]) -> String {
  let mut text = ""
  for check in checks {
    text += "\{check.code}=\{check.passed};"
  }
  text
}
