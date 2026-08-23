///|
pub struct SetupTransition {
  from_group : String
  to_group : String
  duration : Int
  occurrences : Int
} derive(Eq, Debug)

///|
pub struct SetupGroupLoad {
  group : String
  operation_count : Int
  work : Int
  incoming_setup : Int
} derive(Eq, Debug)

///|
fn transition_index(
  transitions : Array[SetupTransition],
  from_group : String,
  to_group : String,
) -> Int? {
  for index, transition in transitions {
    if transition.from_group == from_group && transition.to_group == to_group {
      return Some(index)
    }
  }
  None
}

///|
pub fn setup_transition_matrix(input : ScheduleInput) -> Array[SetupTransition] {
  let result : Array[SetupTransition] = []
  for setup in input.setup_times {
    match transition_index(result, setup.from_group, setup.to_group) {
      Some(index) => {
        let current = result[index]
        result[index] = { ..current, occurrences: current.occurrences + 1 }
      }
      None =>
        result.push({
          from_group: setup.from_group,
          to_group: setup.to_group,
          duration: setup.duration,
          occurrences: 1,
        })
    }
  }
  result
}

///|
fn group_index(groups : Array[SetupGroupLoad], group : String) -> Int? {
  for index, item in groups {
    if item.group == group {
      return Some(index)
    }
  }
  None
}

///|
pub fn setup_group_loads(input : ScheduleInput) -> Array[SetupGroupLoad] {
  let result : Array[SetupGroupLoad] = []
  for job in input.jobs {
    for operation in job.operations {
      match group_index(result, operation.setup_group) {
        Some(index) => {
          let current = result[index]
          result[index] = {
            ..current,
            operation_count: current.operation_count + 1,
            work: current.work + operation.duration,
          }
        }
        None =>
          result.push({
            group: operation.setup_group,
            operation_count: 1,
            work: operation.duration,
            incoming_setup: 0,
          })
      }
    }
  }
  for transition in setup_transition_matrix(input) {
    match group_index(result, transition.to_group) {
      Some(index) => {
        let current = result[index]
        result[index] = {
          ..current,
          incoming_setup: current.incoming_setup + transition.duration,
        }
      }
      None => ()
    }
  }
  result
}

///|
fn job_first_group(job : Job) -> String {
  if job.operations.length() == 0 {
    ""
  } else {
    job.operations[0].setup_group
  }
}

///|
fn job_last_group(job : Job) -> String {
  if job.operations.length() == 0 {
    ""
  } else {
    job.operations[job.operations.length() - 1].setup_group
  }
}

///|
pub fn setup_cost_for_order(input : ScheduleInput, jobs : Array[Job]) -> Int {
  let mut total = 0
  for job in jobs {
    for index in 1..<job.operations.length() {
      total += setup_duration(
        input.setup_times,
        job.operations[index - 1].setup_group,
        job.operations[index].setup_group,
      )
    }
  }
  for index in 1..<jobs.length() {
    total += setup_duration(
      input.setup_times,
      job_last_group(jobs[index - 1]),
      job_first_group(jobs[index]),
    )
  }
  total
}

///|
pub fn setup_order_by_cost(
  input : ScheduleInput,
  jobs : Array[Job],
) -> Array[Job] {
  let remaining = jobs.copy()
  let result : Array[Job] = []
  while remaining.length() > 0 {
    let mut selected = 0
    let mut selected_cost = 1_000_000_000
    for index, candidate in remaining {
      let mut transition_cost = 0
      if result.length() > 0 {
        transition_cost = setup_duration(
          input.setup_times,
          job_last_group(result[result.length() - 1]),
          job_first_group(candidate),
        )
      }
      if transition_cost < selected_cost {
        selected = index
        selected_cost = transition_cost
      }
    }
    result.push(remaining[selected])
    let _ = remaining.remove(selected)
  }
  result
}

///|
pub fn setup_transition_table(transitions : Array[SetupTransition]) -> String {
  let mut text = "from_group,to_group,duration,occurrences\n"
  for transition in transitions {
    text += "\{transition.from_group},\{transition.to_group},\{transition.duration},\{transition.occurrences}\n"
  }
  text
}

///|
pub fn setup_group_table(groups : Array[SetupGroupLoad]) -> String {
  let mut text = "group,operation_count,work,incoming_setup\n"
  for group in groups {
    text += "\{group.group},\{group.operation_count},\{group.work},\{group.incoming_setup}\n"
  }
  text
}

///|
pub fn setup_summary(input : ScheduleInput) -> String {
  let transitions = setup_transition_matrix(input)
  let groups = setup_group_loads(input)
  "transitions=\{transitions.length()}, groups=\{groups.length()}, baseline_cost=\{setup_cost_for_order(input, input.jobs)}"
}

///|
pub fn setup_signature(input : ScheduleInput) -> String {
  let mut text = ""
  for transition in setup_transition_matrix(input) {
    text += "\{transition.from_group}>\{transition.to_group}:\{transition.duration};"
  }
  text
}
