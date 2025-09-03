extension Optional {

  public func run<E>(_ block: (Wrapped) throws(E) -> Void) throws(E) where E: Error {
    if case .some(let wrapped) = self {
      try block(wrapped)
    }
  }

}
