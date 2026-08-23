///|
pub struct NeighborhoodKind {
  code : Int
} derive(Eq, Debug)

///|
pub fn NeighborhoodKind::swap() -> NeighborhoodKind {
  { code: 0 }
}

///|
pub fn NeighborhoodKind::insert() -> NeighborhoodKind {
  { code: 1 }
}

///|
pub fn NeighborhoodKind::reverse() -> NeighborhoodKind {
  { code: 2 }
}

///|
pub fn NeighborhoodKind::name(self : NeighborhoodKind) -> String {
  match self.code {
    0 => "swap"
    1 => "insert"
    _ => "reverse"
  }
}

///|
pub struct NeighborhoodMove {
  kind : NeighborhoodKind
  left : Int
  right : Int
} derive(Eq, Debug)

///|
pub fn NeighborhoodMove::new(
  kind~ : NeighborhoodKind,
  left~ : Int,
  right~ : Int,
) -> NeighborhoodMove {
  { kind, left, right }
}

///|
fn insert_job(jobs : Array[Job], from : Int, to : Int) -> Array[Job] {
  let result = jobs.copy()
  if from < 0 || to < 0 || from >= result.length() || to >= result.length() {
    return result
  }
  let value = result.remove(from)
  result.insert(to, value)
  result
}

///|
fn reverse_jobs(jobs : Array[Job], left : Int, right : Int) -> Array[Job] {
  let result = jobs.copy()
  if left < 0 || right >= result.length() || left >= right {
    return result
  }
  let mut low = left
  let mut high = right
  while low < high {
    let value = result[low]
    result[low] = result[high]
    result[high] = value
    low += 1
    high -= 1
  }
  result
}

///|
pub fn apply_neighborhood(
  jobs : Array[Job],
  movement : NeighborhoodMove,
) -> Array[Job] {
  match movement.kind.code {
    0 => swap_jobs(jobs, movement.left, movement.right)
    1 => insert_job(jobs, movement.left, movement.right)
    _ => reverse_jobs(jobs, movement.left, movement.right)
  }
}

///|
pub fn job_order_signature(jobs : Array[Job]) -> String {
  let mut result = ""
  for i in 0..<jobs.length() {
    if i > 0 {
      result += ">"
    }
    result += jobs[i].id
  }
  result
}

///|
pub fn generate_job_neighbors(
  jobs : Array[Job],
  kind : NeighborhoodKind,
  limit~ : Int,
) -> Array[Array[Job]] {
  let result : Array[Array[Job]] = []
  if jobs.length() < 2 || limit <= 0 {
    return result
  }
  let mut produced = 0
  for left in 0..<jobs.length() {
    for right in (left + 1)..<jobs.length() {
      if produced >= limit {
        break
      }
      let candidate = apply_neighborhood(
        jobs,
        NeighborhoodMove::new(kind~, left~, right~),
      )
      if job_order_signature(candidate) != job_order_signature(jobs) {
        result.push(candidate)
        produced += 1
      }
    }
    if produced >= limit {
      break
    }
  }
  result
}

///|
pub fn NeighborhoodKind::all() -> Array[NeighborhoodKind] {
  [
    NeighborhoodKind::swap(),
    NeighborhoodKind::insert(),
    NeighborhoodKind::reverse(),
  ]
}

///|
pub fn neighborhood_size(jobs : Array[Job], kind : NeighborhoodKind) -> Int {
  generate_job_neighbors(jobs, kind, limit=1_000_000).length()
}
