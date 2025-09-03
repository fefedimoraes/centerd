import Darwin

let commands: [String: () -> CliCommand] = [
  "active": {
    ActiveCommand(
      delay: CommandLine.arguments.getArgumentValue(argName: "--delay", convert: { UInt32($0) })
        ?? nil
    )
  },
  "apps": {
    return AppsCommand()
  },
  "cycle": {
    guard let appName = CommandLine.arguments.getArgumentValue(argName: "--app", convert: { $0 })
    else {
      return UsageCommand()
    }
    let step =
      switch CommandLine.arguments.dropFirst(2).first {
      case "backwards": -1
      case "forward": 1
      case nil: 1
      default: 1
      }
    return CycleCommand(
      appName: appName,
      step: step,
      tolerance: CommandLine.arguments.getArgumentValue(
        argName: "--tolerance", convert: { Double($0)! }) ?? 2.0
    )
  },
]

func main() -> Int32 {
  guard let commandName = CommandLine.arguments.dropFirst().first else {
    print("Command is required. [Avaliable Commands: \(commands.keys)]")
    return EX_USAGE
  }
  guard let command = commands[commandName] else {
    print(
      "Command not found. [Requested Command: \(commandName)] [Avaliable Commands: \(commands.keys)]"
    )
    return EX_USAGE
  }
  return command().exec()
}

exit(main())
