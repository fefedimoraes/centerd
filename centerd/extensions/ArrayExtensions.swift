extension Array where Element : Equatable {

    func getArgumentValue(argName: Element) -> Element? {
        guard let index = self.firstIndex(of: argName) else {
            return nil
        }

        if self.count <= index + 1 {
            return nil
        }

        return self[index + 1]
    }
}
