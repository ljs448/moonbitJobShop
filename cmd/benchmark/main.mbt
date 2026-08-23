///|
fn main {
  println("benchmark=moonbitJobShop/reference-suite")
  match @jobshop.run_benchmark_suite() {
    Ok(summaries) =>
      for summary in summaries {
        println(@jobshop.BenchmarkSummary::compact_line(summary))
      }
    Err(message) => println("benchmark_error=\{message}")
  }
  let dataset = @jobshop.benchmark_dataset()
  println("dataset=\{dataset.describe()}")
  match dataset.run() {
    Ok(summaries) => {
      println(@jobshop.dataset_result_table(dataset, summaries))
      println(
        "dataset_checksum_length=\{@jobshop.dataset_checksum_length(summaries)}",
      )
    }
    Err(message) => println("dataset_error=\{message}")
  }
}
