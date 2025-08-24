import Foundation

class UsageCommand : CliCommand {

    func exec() -> Int32 {
        print("Check usage.")
        return EX_USAGE
    }

}
