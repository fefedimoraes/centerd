import Cocoa
import Foundation

public class CenterService: NSObject, CenterProtocol {
  public func cycle(_ requestData: Data, withReply reply: @escaping (Data) -> Void) {
    do {
      // Decode incoming request
      let request = try JSONDecoder().decode(CycleRequest.self, from: requestData)
      guard
        let windows = try NSWorkspace.shared.getRunningApplication(request.applicationName)?
          .getWindows()
      else {
        reply(Data())
        return
      }

      let controller = OverlayWindowController(windows: windows)
      controller.showWindow(self)
      Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in controller.close() }

      let result = CycleResult(direction: request.direction, result: 123)
      // Encode reply
      let replyData = try JSONEncoder().encode(result)
      reply(replyData)
    } catch {
      print("Failed to decode or encode: \(error)")
      reply(Data())  // send empty data on error
    }
  }
}
