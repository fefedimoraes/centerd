import Combine
import SwiftUI

/// A single selectable row in the switcher.
public struct SwitcherItem: Identifiable {
    public let id: CGWindowID
    let title: String
}

/// Observable state backing the switcher UI. Mutated by `SwitcherController` on the main actor;
/// the SwiftUI view is a pure function of this state.
@MainActor
public final class SwitcherViewModel: ObservableObject {

    @Published var appName: String = ""
    @Published var appIcon: Image?
    @Published var items: [SwitcherItem] = []
    @Published var selection: Int = 0

}
