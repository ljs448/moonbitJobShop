///|
pub struct BenchmarkCase {
  input : ScheduleInput
  job_count : Int
  machine_count : Int
  operation_count : Int
  signature : String
} derive(Eq, Debug)

///|
pub struct BenchmarkSummary {
  schedule : Schedule
  jobs : Int
  machines : Int
  operations : Int
  repeats : Int
  makespan : Int
  tardiness : Int
  checksum : String
  score : Int
} derive(Eq, Debug)

///|
fn benchmark_machine_ids(count : Int) -> Array[String] {
  let result : Array[String] = []
  let total = if count <= 0 { 1 } else { count }
  for index in 0..<total {
    result.push("machine-\{index + 1}")
  }
  result
}

///|
fn benchmark_job(
  job_index : Int,
  operations_per_job : Int,
  machine_ids : Array[String],
) -> Job {
  let operations : Array[Operation] = []
  let count = if operations_per_job <= 0 { 1 } else { operations_per_job }
  for operation_index in 0..<count {
    let primary = (job_index + operation_index) % machine_ids.length()
    let secondary = (primary + 1) % machine_ids.length()
    let candidates = if machine_ids.length() == 1 {
      [machine_ids[primary]]
    } else {
      [machine_ids[primary], machine_ids[secondary]]
    }
    let duration = 2 + (job_index * 3 + operation_index * 5) % 7
    let group = if operation_index % 3 == 0 {
      "rough"
    } else if operation_index % 3 == 1 {
      "finish"
    } else {
      "inspect"
    }
    operations.push(
      Operation::new(
        id="job-\{job_index + 1}-op-\{operation_index + 1}",
        name="Operation \{operation_index + 1}",
        duration~,
        machine_ids=candidates,
        setup_group=group,
      ),
    )
  }
  Job::new(
    id="job-\{job_index + 1}",
    name="Benchmark job \{job_index + 1}",
    due_time=count * 7 + job_index % 11 + 4,
    operations~,
  )
}

///|
pub fn benchmark_case(
  jobs~ : Int,
  machines~ : Int,
  operations_per_job~ : Int,
) -> BenchmarkCase {
  let machine_ids = benchmark_machine_ids(machines)
  let job_count = if jobs < 0 { 0 } else { jobs }
  let jobs_array : Array[Job] = []
  for job_index in 0..<job_count {
    jobs_array.push(benchmark_job(job_index, operations_per_job, machine_ids))
  }
  let operations_count = jobs_array.length() *
    (if operations_per_job <= 0 { 1 } else { operations_per_job })
  let input = ScheduleInput::new(
    jobs=jobs_array,
    machines=machine_ids.map(id => Machine::new(id~, name="Machine \{id}")),
    setup_times=[
      SetupTime::new(from_group="rough", to_group="finish", duration=1),
      SetupTime::new(from_group="finish", to_group="inspect", duration=1),
      SetupTime::new(from_group="inspect", to_group="rough", duration=2),
    ],
  )
  {
    input,
    job_count,
    machine_count: machine_ids.length(),
    operation_count: operations_count,
    signature: "\{job_count}x\{machine_ids.length()}x\{operations_count}",
  }
}

///|
pub fn run_benchmark(
  case : BenchmarkCase,
  repeats~ : Int,
) -> Result[BenchmarkSummary, String] {
  if repeats <= 0 {
    return Err("benchmark repeats must be positive")
  }
  let mut last : Schedule? = None
  for _ in 0..<repeats {
    match dispatch(case.input) {
      Ok(schedule) => last = Some(schedule)
      Err(message) => return Err(message)
    }
  }
  match last {
    Some(schedule) => {
      let evaluation = evaluate(
        schedule,
        case.input,
        ObjectiveWeights::balanced(),
      )
      Ok({
        schedule,
        jobs: case.job_count,
        machines: case.machine_count,
        operations: case.operation_count,
        repeats,
        makespan: schedule.makespan(),
        tardiness: total_tardiness(schedule, case.input.jobs),
        checksum: schedule.signature(),
        score: evaluation.score,
      })
    }
    None => Err("benchmark produced no schedule")
  }
}

///|
pub fn BenchmarkSummary::line(self : BenchmarkSummary) -> String {
  "jobs=\{self.jobs}, machines=\{self.machines}, operations=\{self.operations}, repeats=\{self.repeats}, makespan=\{self.makespan}, tardiness=\{self.tardiness}, score=\{self.score}, checksum=\{self.checksum}"
}

///|
pub fn BenchmarkSummary::compact_line(self : BenchmarkSummary) -> String {
  "jobs=\{self.jobs}, machines=\{self.machines}, operations=\{self.operations}, repeats=\{self.repeats}, makespan=\{self.makespan}, tardiness=\{self.tardiness}, score=\{self.score}, checksum_length=\{self.checksum.length()}"
}
