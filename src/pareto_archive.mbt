///|
pub struct ParetoArchive {
  points : Array[ParetoPoint]
} derive(Eq, Debug)

///|
pub fn ParetoArchive::new() -> ParetoArchive {
  { points: [] }
}

///|
pub fn ParetoArchive::add(
  self : ParetoArchive,
  point : ParetoPoint,
) -> ParetoArchive {
  let points = self.points.copy()
  points.push(point)
  { points: pareto_frontier(points) }
}

///|
pub fn ParetoArchive::add_all(
  self : ParetoArchive,
  points : Array[ParetoPoint],
) -> ParetoArchive {
  let all = self.points.copy()
  for point in points {
    all.push(point)
  }
  { points: pareto_frontier(all) }
}

///|
pub fn ParetoArchive::merge(
  self : ParetoArchive,
  other : ParetoArchive,
) -> ParetoArchive {
  self.add_all(other.points)
}

///|
pub fn ParetoArchive::frontier(self : ParetoArchive) -> Array[ParetoPoint] {
  self.points
}

///|
pub fn ParetoArchive::size(self : ParetoArchive) -> Int {
  self.points.length()
}

///|
pub fn ParetoArchive::best(
  self : ParetoArchive,
  weights : ObjectiveWeights,
) -> ParetoPoint? {
  choose_compromise(self.points, weights)
}

///|
pub fn pareto_rank(points : Array[ParetoPoint]) -> Array[Int] {
  let ranks : Array[Int] = []
  for i in 0..<points.length() {
    let mut rank = 0
    for j in 0..<points.length() {
      if i != j && points[j].objectives.dominates(points[i].objectives) {
        rank += 1
      }
    }
    ranks.push(rank)
  }
  ranks
}

///|
pub fn pareto_layer_count(points : Array[ParetoPoint]) -> Int {
  let ranks = pareto_rank(points)
  let mut maximum = 0
  for rank in ranks {
    if rank > maximum {
      maximum = rank
    }
  }
  if ranks.length() == 0 {
    0
  } else {
    maximum + 1
  }
}

///|
pub fn objective_normalize(
  value : ObjectiveVector,
  minimum : ObjectiveVector,
  maximum : ObjectiveVector,
) -> ObjectiveVector {
  let scale = fn(current : Int, low : Int, high : Int) -> Int {
    if high <= low {
      0
    } else {
      (current - low) * 100 / (high - low)
    }
  }
  ObjectiveVector::new(
    makespan=scale(value.makespan, minimum.makespan, maximum.makespan),
    tardiness=scale(value.tardiness, minimum.tardiness, maximum.tardiness),
    load_balance=scale(
      value.load_balance,
      minimum.load_balance,
      maximum.load_balance,
    ),
    setup_count=scale(
      value.setup_count,
      minimum.setup_count,
      maximum.setup_count,
    ),
  )
}
