///|
pub struct DatasetEntry {
  name : String
  jobs : Int
  machines : Int
  operations : Int
  repeats : Int
  case : BenchmarkCase
} derive(Eq, Debug)

///|
pub struct BenchmarkDataset {
  name : String
  version : String
  cases : Array[DatasetEntry]
} derive(Eq, Debug)

///|
fn dataset_entry(
  name : String,
  jobs : Int,
  machines : Int,
  operations : Int,
  repeats : Int,
) -> DatasetEntry {
  {
    name,
    jobs,
    machines,
    operations,
    repeats,
    case: benchmark_case(jobs~, machines~, operations_per_job=operations),
  }
}

///|
pub fn benchmark_dataset() -> BenchmarkDataset {
  {
    name: "moonbit-jobshop-reference",
    version: "2026.08",
    cases: [
      dataset_entry("tiny-2x2", 2, 2, 2, 5),
      dataset_entry("small-6x3", 6, 3, 4, 3),
      dataset_entry("medium-12x4", 12, 4, 5, 2),
      dataset_entry("large-20x5", 20, 5, 6, 1),
    ],
  }
}

///|
pub fn BenchmarkDataset::manifest(self : BenchmarkDataset) -> String {
  let mut text = "name,version,case,jobs,machines,operations,repeats\n"
  for entry in self.cases {
    text += "\{self.name},\{self.version},\{entry.name},\{entry.jobs},\{entry.machines},\{entry.operations},\{entry.repeats}\n"
  }
  text
}

///|
pub fn BenchmarkDataset::case_names(self : BenchmarkDataset) -> Array[String] {
  let result : Array[String] = []
  for entry in self.cases {
    result.push(entry.name)
  }
  result
}

///|
pub fn BenchmarkDataset::describe(self : BenchmarkDataset) -> String {
  "\{self.name}@\{self.version}, cases=\{self.cases.length()}"
}

///|
pub fn BenchmarkDataset::run(
  self : BenchmarkDataset,
) -> Result[Array[BenchmarkSummary], String] {
  let result : Array[BenchmarkSummary] = []
  for entry in self.cases {
    match run_benchmark(entry.case, repeats=entry.repeats) {
      Ok(summary) => result.push(summary)
      Err(message) => return Err(message)
    }
  }
  Ok(result)
}

///|
pub fn dataset_result_table(
  dataset : BenchmarkDataset,
  summaries : Array[BenchmarkSummary],
) -> String {
  let mut text = "case,jobs,machines,operations,repeats,makespan,tardiness,score,checksum_length\n"
  for index in 0..<summaries.length() {
    let entry = dataset.cases[index]
    let summary = summaries[index]
    text += "\{entry.name},\{summary.jobs},\{summary.machines},\{summary.operations},\{summary.repeats},\{summary.makespan},\{summary.tardiness},\{summary.score},\{summary.checksum.length()}\n"
  }
  text
}

///|
pub fn dataset_checksum(summaries : Array[BenchmarkSummary]) -> String {
  let mut text = ""
  for summary in summaries {
    text += summary.checksum + ";"
  }
  text
}

///|
pub fn dataset_checksum_length(summaries : Array[BenchmarkSummary]) -> Int {
  dataset_checksum(summaries).length()
}

///|
pub fn dataset_total_operations(dataset : BenchmarkDataset) -> Int {
  let mut total = 0
  for entry in dataset.cases {
    total += entry.operations * entry.jobs
  }
  total
}

///|
pub fn dataset_scale_summary(dataset : BenchmarkDataset) -> String {
  "cases=\{dataset.cases.length()}, total_operations=\{dataset_total_operations(dataset)}, names=\{dataset.case_names().join(",")}"
}
