import Cocoa

class AppsCommand: CliCommand {

  func exec() -> Int32 {
    let apps = Set(NSWorkspace.shared.runningApplications.compactMap({ $0.localizedName }))
    print(apps.sorted().joined(separator: "\n"))
    return EX_OK
  }

}
