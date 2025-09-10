import Foundation

public class CenterClient {
  private let connection: NSXPCConnection
  private var proxy: CenterProtocol {
    return connection.remoteObjectProxyWithErrorHandler { error in
      print("XPC Error: \(error)")
    } as! CenterProtocol
  }

  public init(endpoint: NSXPCListenerEndpoint) {
    connection = NSXPCConnection(listenerEndpoint: endpoint)
    connection.remoteObjectInterface = NSXPCInterface(with: CenterProtocol.self)
    connection.resume()
  }

  public func cycleAsync(_ request: CycleRequest, completion: @escaping (CycleResult?) -> Void) {
    do {
      let data = try JSONEncoder().encode(request)
      proxy.cycle(data) { replyData in
        guard let result = try? JSONDecoder().decode(CycleResult.self, from: replyData) else {
          completion(nil)
          return
        }
        completion(result)
      }
    } catch {
      print("Encoding error: \(error)")
      completion(nil)
    }
  }

  deinit {
    connection.invalidate()
  }
}
