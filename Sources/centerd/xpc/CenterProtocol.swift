import Foundation

public enum CycleDirection: Codable {
  case forward
  case backward
}

public struct CycleRequest: Codable {
  let applicationName: String
  let direction: CycleDirection
}

public struct CycleResult: Codable {
  let direction: CycleDirection
  let result: Int
}

@objc
public protocol CenterProtocol {
  func cycle(_ requestData: Data, withReply reply: @escaping (Data) -> Void)
}
