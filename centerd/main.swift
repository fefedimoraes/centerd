import Darwin

let commands: [String : () -> CliCommand] = [
    "test": {
        TestCommand(
            delay: CommandLine.arguments.getArgumentValue(argName: "--delay", convert: { UInt32($0) }) ?? nil,
        )
    },
    "active": {
        ActiveCommand(
            delay: CommandLine.arguments.getArgumentValue(argName: "--delay", convert: { UInt32($0) }) ?? nil,
        )
    },
]

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
