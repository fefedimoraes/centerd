import CoreFoundation

extension CGPoint {

  public func distance(point: CGPoint?) -> CGFloat {
    if case .some(let point) = point {
      let dx = self.x - point.x
      let dy = self.y - point.y
      return sqrt(dx * dx + dy * dy)
    } else {
      return CGFloat.greatestFiniteMagnitude
    }
  }

}
