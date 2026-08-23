///|
pub struct TraceEvent {
  sequence : Int
  job_id : String
  operation_id : String
  machine_id : String
  start : Int
  end : Int
  duration : Int
} derive(Eq, Debug)

///|
pub fn schedule_trace(schedule : Schedule) -> Array[TraceEvent] {
  let ordered = schedule.operations.copy()
  let result : Array[TraceEvent] = []
  for sequence, operation in ordered {
    result.push({
      sequence,
      job_id: operation.job_id,
      operation_id: operation.operation_id,
      machine_id: operation.machine_id,
      start: operation.start,
      end: operation.end,
      duration: operation.end - operation.start,
    })
  }
  result
}

///|
pub fn trace_duration(trace : Array[TraceEvent]) -> Int {
  let mut total = 0
  for event in trace {
    total += event.duration
  }
  total
}

///|
pub fn trace_checksum(trace : Array[TraceEvent]) -> String {
  let mut text = ""
  for event in trace {
    text += "\{event.job_id}:\{event.operation_id}@\{event.machine_id}:\{event.start}-\{event.end};"
  }
  text
}

///|
pub fn trace_csv(trace : Array[TraceEvent]) -> String {
  let mut text = "sequence,job,operation,machine,start,end,duration\n"
  for event in trace {
    text += "\{event.sequence},\{event.job_id},\{event.operation_id},\{event.machine_id},\{event.start},\{event.end},\{event.duration}\n"
  }
  text
}

///|
pub fn trace_json(trace : Array[TraceEvent]) -> String {
  let mut text = "["
  for index, event in trace {
    if index > 0 {
      text += ","
    }
    text += "{\"sequence\":\{event.sequence},\"job\":\"\{event.job_id}\",\"operation\":\"\{event.operation_id}\",\"machine\":\"\{event.machine_id}\",\"start\":\{event.start},\"end\":\{event.end}}"
  }
  text + "]"
}

///|
pub fn trace_machine_count(trace : Array[TraceEvent]) -> Int {
  let machines : Array[String] = []
  for event in trace {
    if !machines.contains(event.machine_id) {
      machines.push(event.machine_id)
    }
  }
  machines.length()
}

///|
pub fn trace_job_count(trace : Array[TraceEvent]) -> Int {
  let jobs : Array[String] = []
  for event in trace {
    if !jobs.contains(event.job_id) {
      jobs.push(event.job_id)
    }
  }
  jobs.length()
}

///|
pub fn trace_summary(trace : Array[TraceEvent]) -> String {
  "events=\{trace.length()}, jobs=\{trace_job_count(trace)}, machines=\{trace_machine_count(trace)}, duration=\{trace_duration(trace)}"
}

///|
pub fn trace_is_ordered(trace : Array[TraceEvent]) -> Bool {
  for index in 1..<trace.length() {
    if trace[index].sequence < trace[index - 1].sequence {
      return false
    }
  }
  true
}

///|
pub fn trace_report(schedule : Schedule) -> String {
  let trace = schedule_trace(schedule)
  trace_summary(trace) + "\n" + trace_csv(trace)
}
