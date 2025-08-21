import Foundation

extension UInt32? {

    public func sleep() {
        self.run { unistd.sleep($0) }
    }

}
