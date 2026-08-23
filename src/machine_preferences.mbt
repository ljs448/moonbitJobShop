///|
pub struct MachinePreferenceResult {
  preferred_machine : String
  schedule : Schedule
  score : Int
  makespan : Int
  load_balance : Int
} derive(Eq, Debug)

///|
fn reordered_machine_ids(
  machine_ids : Array[String],
  preferred : String,
) -> Array[String] {
  let result : Array[String] = []
  for machine_id in machine_ids {
    if machine_id == preferred {
      result.push(machine_id)
    }
  }
  for machine_id in machine_ids {
    if machine_id != preferred {
      result.push(machine_id)
    }
  }
  result
}

///|
fn input_with_preference(
  input : ScheduleInput,
  preferred : String,
) -> ScheduleInput {
  let jobs : Array[Job] = []
  for job in input.jobs {
    let operations : Array[Operation] = []
    for operation in job.operations {
      operations.push(
        Operation::new(
          id=operation.id,
          name=operation.name,
          duration=operation.duration,
          machine_ids=reordered_machine_ids(operation.machine_ids, preferred),
          setup_group=operation.setup_group,
        ),
      )
    }
    jobs.push(
      Job::new(id=job.id, name=job.name, due_time=job.due_time, operations~),
    )
  }
  { ..input, jobs, }
}

///|
pub fn dispatch_with_machine_preference(
  input : ScheduleInput,
  preferred_machine : String,
) -> Result[MachinePreferenceResult, String] {
  let adjusted = input_with_preference(input, preferred_machine)
  match dispatch(adjusted) {
    Ok(schedule) => {
      let evaluation = evaluate(schedule, input, ObjectiveWeights::balanced())
      Ok({
        preferred_machine,
        schedule,
        score: evaluation.score,
        makespan: evaluation.makespan,
        load_balance: load_balance(schedule, input.machines),
      })
    }
    Err(message) => Err(message)
  }
}

///|
pub fn machine_preference_matrix(
  input : ScheduleInput,
) -> Result[Array[MachinePreferenceResult], String] {
  let result : Array[MachinePreferenceResult] = []
  for machine in input.machines {
    match dispatch_with_machine_preference(input, machine.id) {
      Ok(value) => result.push(value)
      Err(message) => return Err(message)
    }
  }
  Ok(result)
}

///|
pub fn best_machine_preference(
  results : Array[MachinePreferenceResult],
) -> MachinePreferenceResult? {
  if results.length() == 0 {
    return None
  }
  let mut best = results[0]
  for result in results[1:] {
    if result.score < best.score {
      best = result
    }
  }
  Some(best)
}

///|
pub fn machine_preference_table(
  results : Array[MachinePreferenceResult],
) -> String {
  let mut text = "preferred_machine,score,makespan,load_balance,checksum\n"
  for result in results {
    text += "\{result.preferred_machine},\{result.score},\{result.makespan},\{result.load_balance},\{result.schedule.signature()}\n"
  }
  text
}

///|
pub fn machine_preference_summary(
  results : Array[MachinePreferenceResult],
) -> String {
  match best_machine_preference(results) {
    Some(best) =>
      "candidates=\{results.length()}, best=\{best.preferred_machine}, score=\{best.score}"
    None => "candidates=0"
  }
}

///|
pub fn preference_score_range(results : Array[MachinePreferenceResult]) -> Int {
  if results.length() == 0 {
    return 0
  }
  let mut minimum = results[0].score
  let mut maximum = minimum
  for result in results[1:] {
    if result.score < minimum {
      minimum = result.score
    }
    if result.score > maximum {
      maximum = result.score
    }
  }
  maximum - minimum
}

///|
pub fn preference_is_stable(
  left : Array[MachinePreferenceResult],
  right : Array[MachinePreferenceResult],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for index in 0..<left.length() {
    if left[index].schedule.signature() != right[index].schedule.signature() {
      return false
    }
  }
  true
}
