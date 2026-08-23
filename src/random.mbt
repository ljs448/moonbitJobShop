///|
pub struct DeterministicRng {
  state : Int
} derive(Eq, Debug)

///|
pub fn DeterministicRng::new(seed : Int) -> DeterministicRng {
  let normalized = if seed < 0 { -seed } else { seed }
  { state: normalized + 17 }
}

///|
pub fn DeterministicRng::next(
  self : DeterministicRng,
) -> (DeterministicRng, Int) {
  let next_state = (self.state * 1_103 + 12_345) % 1_000_003
  ({ state: next_state }, next_state)
}

///|
pub fn DeterministicRng::next_bounded(
  self : DeterministicRng,
  bound : Int,
) -> (DeterministicRng, Int) {
  if bound <= 0 {
    (self, 0)
  } else {
    let (next, value) = self.next()
    (next, value % bound)
  }
}

///|
fn swap_jobs(jobs : Array[Job], left : Int, right : Int) -> Array[Job] {
  let result = jobs.copy()
  if left >= 0 &&
    right >= 0 &&
    left < result.length() &&
    right < result.length() {
    let value = result[left]
    result[left] = result[right]
    result[right] = value
  }
  result
}

///|
fn rotate_jobs(jobs : Array[Job], offset : Int) -> Array[Job] {
  if jobs.length() == 0 {
    return []
  }
  let result : Array[Job] = []
  let raw = offset % jobs.length()
  let normalized = if raw < 0 { raw + jobs.length() } else { raw }
  for i in 0..<jobs.length() {
    result.push(jobs[(i + normalized) % jobs.length()])
  }
  result
}
