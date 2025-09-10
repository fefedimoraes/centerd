import Foundation

public class CenterDaemon: NSObject, NSXPCListenerDelegate {
  private let listener: NSXPCListener

  public var endpoint: NSXPCListenerEndpoint { listener.endpoint }

  public override init() {
    listener = NSXPCListener.anonymous()
    super.init()
    listener.delegate = self
  }

  public func run() {
    listener.resume()
    RunLoop.current.run()
  }

  public func listener(_ listener: NSXPCListener, _ connection: NSXPCConnection) -> Bool {
    connection.exportedInterface = NSXPCInterface(with: CenterProtocol.self)
    connection.exportedObject = CenterService()
    connection.resume()
    return true
  }
}
