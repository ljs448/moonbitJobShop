///|
pub struct RouteAlternative {
  operation_id : String
  machine_id : String
  position : Int
  duration : Int
  flexibility : Int
  score : Int
} derive(Eq, Debug)

///|
pub fn route_alternatives(operation : Operation) -> Array[RouteAlternative] {
  let result : Array[RouteAlternative] = []
  for index, machine_id in operation.machine_ids {
    let flexibility = operation.machine_ids.length() - index
    result.push({
      operation_id: operation.id,
      machine_id,
      position: index,
      duration: operation.duration,
      flexibility,
      score: operation.duration * 100 + index * 3 - flexibility,
    })
  }
  result
}

///|
pub fn select_fastest_route(operation : Operation) -> RouteAlternative? {
  let alternatives = route_alternatives(operation)
  if alternatives.length() == 0 {
    return None
  }
  let mut best = alternatives[0]
  for alternative in alternatives[1:] {
    if alternative.score < best.score {
      best = alternative
    }
  }
  Some(best)
}

///|
pub fn route_feasibility(
  operation : Operation,
  calendars : Array[MachineCalendar],
  earliest~ : Int,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for machine_id in operation.machine_ids {
    let mut available = true
    for calendar in calendars {
      if calendar.machine_id == machine_id {
        let interval = Interval::new(
          start=calendar.next_available(earliest, operation.duration),
          end=calendar.next_available(earliest, operation.duration) +
            operation.duration,
        )
        available = calendar.is_available(interval)
      }
    }
    result.push(available)
  }
  result
}

///|
pub fn route_width_histogram(input : ScheduleInput) -> Array[Int] {
  let mut maximum = 0
  for job in input.jobs {
    for operation in job.operations {
      if operation.route_width() > maximum {
        maximum = operation.route_width()
      }
    }
  }
  let result : Array[Int] = []
  for _ in 0..<(maximum + 1) {
    result.push(0)
  }
  for job in input.jobs {
    for operation in job.operations {
      result[operation.route_width()] += 1
    }
  }
  result
}

///|
pub fn route_count(input : ScheduleInput) -> Int {
  let mut total = 0
  for job in input.jobs {
    for operation in job.operations {
      total += operation.route_width()
    }
  }
  total
}

///|
pub fn route_summary_table(input : ScheduleInput) -> String {
  let mut text = "job,operation,route_width,preferred_machine\n"
  for job in input.jobs {
    for operation in job.operations {
      let preferred = match select_fastest_route(operation) {
        Some(route) => route.machine_id
        None => ""
      }
      text += "\{job.id},\{operation.id},\{operation.route_width()},\{preferred}\n"
    }
  }
  text
}

///|
pub fn route_signature(operation : Operation) -> String {
  let mut text = operation.id + ":"
  for index, machine_id in operation.machine_ids {
    if index > 0 {
      text += "|"
    }
    text += machine_id
  }
  text
}

///|
pub fn route_flexibility_score(input : ScheduleInput) -> Int {
  let count = input.operation_count()
  if count == 0 {
    0
  } else {
    route_count(input) * 100 / count
  }
}
