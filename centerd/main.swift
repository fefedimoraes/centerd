import Darwin

let commands = [
    "active": getActiveCommand,
]

func getActiveCommand() -> CliCommand {
    let delay = CommandLine.arguments.getArgumentValue(argName: "--delay", convert: { UInt32($0) })
    return ActiveCommand(delay: delay ?? nil)
}

func main() -> Int32 {
    guard let commandName = CommandLine.arguments.dropFirst().first else {
        print("Command is required. [Avaliable Commands: \(commands.keys)]")
        return EX_USAGE
    }
    guard let command = commands[commandName] else {
        print("Command not found. [Requested Command: \(commandName)] [Avaliable Commands: \(commands.keys)]")
        return EX_USAGE
    }
    return command().exec()
}

exit(main())
