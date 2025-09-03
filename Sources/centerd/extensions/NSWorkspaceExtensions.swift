import Cocoa

extension NSWorkspace {

  func getRunningApplication(_ applicationName: String) -> NSRunningApplication? {
    return runningApplications.first(where: {
      $0.localizedName == applicationName
    })
  }

}
