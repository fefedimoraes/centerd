extension Array where Element: Equatable, Element: Hashable {

  public func getArgumentValue<T>(argName: Element, convert: (Element) -> T) -> T? {
    guard let index = self.firstIndex(of: argName) else {
      return nil
    }

    if self.count <= index + 1 {
      return nil
    }

    return convert(self[index + 1])
  }

  public func toSet() -> Set<Element> {
    return Set(self)
  }

}

extension Array {

  public func toDictionary<Key, Value>() -> [Key: Value] where Element == (Key, Value) {
    return Dictionary(uniqueKeysWithValues: self)
  }

}
