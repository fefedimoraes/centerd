import Darwin

func main() -> Int32 {
    let command = CommandLine.arguments.dropFirst().first ?? "active"
    switch command {
    case "active":
        return ActiveWindowCenter().exec()
    default:
        print("Command not found. [Command: \(command)]")
        return EX_NOINPUT
    }
}

exit(main())
