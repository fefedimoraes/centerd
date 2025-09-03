import Foundation

extension Collection {

  func parallelCompactMap<R>(_ transform: @escaping (Element) -> R?) -> [R] {
    var res: [R?] = .init(repeating: nil, count: count)

    let lock = NSRecursiveLock()
    DispatchQueue.concurrentPerform(iterations: count) { i in
      if let result = transform(self[index(startIndex, offsetBy: i)]) {
        lock.lock()
        res[i] = result
        lock.unlock()
      }
    }

    return res.compactMap({ $0 })
  }

}
