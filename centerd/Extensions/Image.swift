import SwiftUI

extension Image {

    public init?(nsImage: NSImage?) {
        guard let nsImage else { return nil }
        self.init(nsImage: nsImage)
    }

}
