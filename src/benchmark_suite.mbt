///|
pub struct BenchmarkScenario {
  name : String
  case : BenchmarkCase
  repeats : Int
} derive(Eq, Debug)

///|
pub fn BenchmarkScenario::new(
  name~ : String,
  case~ : BenchmarkCase,
  repeats~ : Int,
) -> BenchmarkScenario {
  { name, case, repeats }
}

///|
pub fn benchmark_suite() -> Array[BenchmarkScenario] {
  [
    BenchmarkScenario::new(
      name="small-assembly",
      case=benchmark_case(jobs=6, machines=3, operations_per_job=4),
      repeats=3,
    ),
    BenchmarkScenario::new(
      name="medium-flexible",
      case=benchmark_case(jobs=12, machines=4, operations_per_job=5),
      repeats=2,
    ),
    BenchmarkScenario::new(
      name="large-batch",
      case=benchmark_case(jobs=20, machines=5, operations_per_job=6),
      repeats=1,
    ),
  ]
}

///|
pub fn BenchmarkScenario::describe(self : BenchmarkScenario) -> String {
  "name=\{self.name}, \{self.case.signature}, repeats=\{self.repeats}"
}

///|
pub fn benchmark_reference(
  scenario : BenchmarkScenario,
  summary : BenchmarkSummary,
) -> String {
  "scenario=\{scenario.name}, jobs=\{summary.jobs}, machines=\{summary.machines}, operations=\{summary.operations}, makespan=\{summary.makespan}, checksum=\{summary.checksum}"
}

///|
pub fn benchmark_suite_descriptions() -> Array[String] {
  let result : Array[String] = []
  for scenario in benchmark_suite() {
    result.push(scenario.describe())
  }
  result
}

///|
pub fn run_benchmark_suite() -> Result[Array[BenchmarkSummary], String] {
  let result : Array[BenchmarkSummary] = []
  for scenario in benchmark_suite() {
    match run_benchmark(scenario.case, repeats=scenario.repeats) {
      Ok(summary) => result.push(summary)
      Err(message) => return Err(message)
    }
  }
  Ok(result)
}
