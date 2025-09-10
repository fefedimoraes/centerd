import Foundation

public enum CenterClientError: Error {
  case timeout
  case emptyResponse
}

extension CenterClient {
  public func cycle(_ request: CycleRequest, timeout: TimeInterval = 5) throws -> CycleResult? {
    let sema = DispatchSemaphore(value: 0)
    var result: CycleResult?

    cycleAsync(request) { replyData in
      defer { sema.signal() }
      result = replyData
    }

    if sema.wait(timeout: .now() + timeout) == .timedOut {
      throw CenterClientError.timeout
    }

    if result == nil {
      throw CenterClientError.emptyResponse
    }

    return result
  }
}
