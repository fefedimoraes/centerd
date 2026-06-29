import SwiftUI

/// The Alt-Tab-style HUD: an app header above a vertical list of window titles, with the
/// currently selected row highlighted in the system accent color.
struct SwitcherView: View {

    @ObservedObject var model: SwitcherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let icon = model.appIcon {
                    icon
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(model.appName)
                    .font(.headline)
            }
            .padding(.bottom, 2)

            ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(index == model.selection ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(index == model.selection ? Color.accentColor : Color.clear)
                    )
            }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
    }

}
