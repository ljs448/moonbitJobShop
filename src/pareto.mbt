///|
pub struct ObjectiveVector {
  makespan : Int
  tardiness : Int
  load_balance : Int
  setup_count : Int
} derive(Eq, Debug)

///|
pub fn ObjectiveVector::new(
  makespan~ : Int,
  tardiness~ : Int,
  load_balance~ : Int,
  setup_count~ : Int,
) -> ObjectiveVector {
  { makespan, tardiness, load_balance, setup_count }
}

///|
pub fn ObjectiveVector::dominates(
  self : ObjectiveVector,
  other : ObjectiveVector,
) -> Bool {
  let no_worse = self.makespan <= other.makespan &&
    self.tardiness <= other.tardiness &&
    self.load_balance <= other.load_balance &&
    self.setup_count <= other.setup_count
  let strictly_better = self.makespan < other.makespan ||
    self.tardiness < other.tardiness ||
    self.load_balance < other.load_balance ||
    self.setup_count < other.setup_count
  no_worse && strictly_better
}

///|
pub fn ObjectiveVector::weighted_score(
  self : ObjectiveVector,
  weights : ObjectiveWeights,
) -> Int {
  self.makespan * weights.makespan +
  self.tardiness * weights.tardiness +
  self.load_balance * weights.load_balance +
  self.setup_count * weights.setup_count
}

///|
pub fn ObjectiveVector::sum(self : ObjectiveVector) -> Int {
  self.makespan + self.tardiness + self.load_balance + self.setup_count
}

///|
pub fn ObjectiveVector::summary(self : ObjectiveVector) -> String {
  "makespan=\{self.makespan}, tardiness=\{self.tardiness}, balance=\{self.load_balance}, setups=\{self.setup_count}"
}

///|
pub struct ParetoPoint {
  schedule : Schedule
  objectives : ObjectiveVector
  signature : String
} derive(Eq, Debug)

///|
pub fn ParetoPoint::new(
  schedule~ : Schedule,
  objectives~ : ObjectiveVector,
) -> ParetoPoint {
  { schedule, objectives, signature: schedule.signature() }
}

///|
fn point_seen(points : Array[ParetoPoint], signature : String) -> Bool {
  for point in points {
    if point.signature == signature {
      return true
    }
  }
  false
}

///|
pub fn pareto_frontier(points : Array[ParetoPoint]) -> Array[ParetoPoint] {
  let frontier : Array[ParetoPoint] = []
  for i in 0..<points.length() {
    let candidate = points[i]
    if point_seen(frontier, candidate.signature) {
      continue
    }
    let mut dominated = false
    for j in 0..<points.length() {
      if i != j && points[j].objectives.dominates(candidate.objectives) {
        dominated = true
      }
    }
    if !dominated {
      frontier.push(candidate)
    }
  }
  frontier
}

///|
pub fn choose_compromise(
  frontier : Array[ParetoPoint],
  weights : ObjectiveWeights,
) -> ParetoPoint? {
  if frontier.length() == 0 {
    return None
  }
  let mut best = frontier[0]
  let mut best_score = best.objectives.weighted_score(weights)
  for point in frontier[1:] {
    let score = point.objectives.weighted_score(weights)
    if score < best_score ||
      (score == best_score && point.signature < best.signature) {
      best = point
      best_score = score
    }
  }
  Some(best)
}

///|
pub fn pareto_signatures(frontier : Array[ParetoPoint]) -> Array[String] {
  let result : Array[String] = []
  for point in frontier {
    result.push(point.signature)
  }
  result
}
