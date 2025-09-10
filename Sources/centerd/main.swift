import Foundation

func tryLock(_ filePath: String) -> Int32 {
  let fileDescriptor = open(filePath, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR)
  guard fileDescriptor != -1 else {
    return -1
  }

  if flock(fileDescriptor, LOCK_EX | LOCK_NB) != 0 {
    close(fileDescriptor)
    return -1
  }

  return fileDescriptor
}

func unlock(_ fileDescriptor: Int32) {
  flock(fileDescriptor, LOCK_UN)
  close(fileDescriptor)
}

func launchDaemon() {
  let currentProcess = ProcessInfo.processInfo
  let daemonProcess = Process()
  daemonProcess.executableURL = URL(fileURLWithPath: currentProcess.arguments[0])
  daemonProcess.arguments = [daemonCommandLineFlag]
  try? daemonProcess.run()
}

func main() {
  if CommandLine.arguments.first(where: { $0 == daemonCommandLineFlag }) != nil {
    let fileDescriptor = tryLock(daemonLockFile)
    if fileDescriptor == -1 {
      unlock(fileDescriptor)
      print("Daemon is already running")
      return
    }

    let daemon = CenterDaemon()
    let data = try! NSKeyedArchiver.archivedData(
      withRootObject: daemon.endpoint, requiringSecureCoding: true)
    let fileHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: false)
    try! fileHandle.write(contentsOf: data)

    daemon.run()
    unlock(fileDescriptor)
    return
  }

  let fileDescriptor = tryLock(daemonLockFile)
  if fileDescriptor != -1 {
    print("Launching Daemon")
    unlock(fileDescriptor)
    launchDaemon()
  }

  guard let daemonLockFileData = try? Data(contentsOf: URL(fileURLWithPath: daemonLockFile)),
    let daemonEndpoint = try? NSKeyedUnarchiver.unarchivedObject(
      ofClass: NSXPCListenerEndpoint.self, from: daemonLockFileData)
  else {
    print("Could not read daemon endpoint")
    return
  }

  guard
    let applicationName = CommandLine.arguments.getArgumentValue(argName: "--app", convert: { $0 })
  else {
    return
  }
  let result = try? CenterClient(endpoint: daemonEndpoint).cycle(
    CycleRequest(applicationName: applicationName, direction: .forward)
  )
  print(result)
}

main()
