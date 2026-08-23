///|
pub struct LedgerEntry {
  sequence : Int
  job_id : String
  operation_id : String
  machine_id : String
  setup_group : String
  start : Int
  end : Int
  duration : Int
} derive(Eq, Debug)

///|
pub struct OperationalLedger {
  entries : Array[LedgerEntry]
  makespan : Int
  total_work : Int
  machine_count : Int
  job_count : Int
} derive(Eq, Debug)

///|
pub fn build_ledger(schedule : Schedule) -> OperationalLedger {
  let entries : Array[LedgerEntry] = []
  let machines : Array[String] = []
  let jobs : Array[String] = []
  let mut total_work = 0
  for sequence, operation in schedule.operations {
    if !machines.contains(operation.machine_id) {
      machines.push(operation.machine_id)
    }
    if !jobs.contains(operation.job_id) {
      jobs.push(operation.job_id)
    }
    let duration = operation.end - operation.start
    total_work += duration
    entries.push({
      sequence,
      job_id: operation.job_id,
      operation_id: operation.operation_id,
      machine_id: operation.machine_id,
      setup_group: operation.setup_group,
      start: operation.start,
      end: operation.end,
      duration,
    })
  }
  {
    entries,
    makespan: schedule.makespan(),
    total_work,
    machine_count: machines.length(),
    job_count: jobs.length(),
  }
}

///|
pub fn OperationalLedger::entry_count(self : OperationalLedger) -> Int {
  self.entries.length()
}

///|
pub fn OperationalLedger::utilization(self : OperationalLedger) -> Int {
  if self.makespan == 0 || self.machine_count == 0 {
    0
  } else {
    self.total_work * 100 / (self.makespan * self.machine_count)
  }
}

///|
pub fn OperationalLedger::summary(self : OperationalLedger) -> String {
  "entries=\{self.entries.length()}, jobs=\{self.job_count}, machines=\{self.machine_count}, work=\{self.total_work}, makespan=\{self.makespan}, utilization=\{self.utilization()}"
}

///|
pub fn ledger_csv(ledger : OperationalLedger) -> String {
  let mut text = "sequence,job,operation,machine,setup_group,start,end,duration\n"
  for entry in ledger.entries {
    text += "\{entry.sequence},\{entry.job_id},\{entry.operation_id},\{entry.machine_id},\{entry.setup_group},\{entry.start},\{entry.end},\{entry.duration}\n"
  }
  text
}

///|
pub fn ledger_machine_work(
  ledger : OperationalLedger,
  machine_id : String,
) -> Int {
  let mut total = 0
  for entry in ledger.entries {
    if entry.machine_id == machine_id {
      total += entry.duration
    }
  }
  total
}

///|
pub fn ledger_job_work(ledger : OperationalLedger, job_id : String) -> Int {
  let mut total = 0
  for entry in ledger.entries {
    if entry.job_id == job_id {
      total += entry.duration
    }
  }
  total
}

///|
pub fn ledger_machine_ids(ledger : OperationalLedger) -> Array[String] {
  let result : Array[String] = []
  for entry in ledger.entries {
    if !result.contains(entry.machine_id) {
      result.push(entry.machine_id)
    }
  }
  result
}

///|
pub fn ledger_job_ids(ledger : OperationalLedger) -> Array[String] {
  let result : Array[String] = []
  for entry in ledger.entries {
    if !result.contains(entry.job_id) {
      result.push(entry.job_id)
    }
  }
  result
}

///|
pub fn ledger_machine_table(ledger : OperationalLedger) -> String {
  let mut text = "machine,work,share_percent\n"
  for machine_id in ledger_machine_ids(ledger) {
    let work = ledger_machine_work(ledger, machine_id)
    let share = if ledger.total_work == 0 {
      0
    } else {
      work * 100 / ledger.total_work
    }
    text += "\{machine_id},\{work},\{share}\n"
  }
  text
}

///|
pub fn ledger_job_table(ledger : OperationalLedger) -> String {
  let mut text = "job,work\n"
  for job_id in ledger_job_ids(ledger) {
    text += "\{job_id},\{ledger_job_work(ledger, job_id)}\n"
  }
  text
}

///|
pub fn ledger_integrity(ledger : OperationalLedger) -> Bool {
  for entry in ledger.entries {
    if entry.start < 0 ||
      entry.end <= entry.start ||
      entry.duration != entry.end - entry.start {
      return false
    }
  }
  true
}

///|
pub fn ledger_checksum(ledger : OperationalLedger) -> String {
  let mut text = "\{ledger.makespan}:"
  for entry in ledger.entries {
    text += "\{entry.job_id}/\{entry.operation_id}@\{entry.machine_id}:\{entry.start}-\{entry.end};"
  }
  text
}

///|
pub fn ledger_report(schedule : Schedule) -> String {
  let ledger = build_ledger(schedule)
  "# Operational ledger\n" +
  ledger.summary() +
  "\n" +
  ledger_machine_table(ledger) +
  ledger_csv(ledger)
}

///|
pub fn ledger_matches_schedule(
  ledger : OperationalLedger,
  schedule : Schedule,
) -> Bool {
  ledger.entry_count() == schedule.operation_count() &&
  ledger.makespan == schedule.makespan() &&
  ledger_integrity(ledger)
}
