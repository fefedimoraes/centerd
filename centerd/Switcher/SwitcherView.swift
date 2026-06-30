import SwiftUI

/// The Alt-Tab-style HUD: an app header above a vertical list of window titles, with the
/// currently selected row highlighted.
///
/// On macOS 26+ the card and the selection highlight use Liquid Glass (`glassEffect`), and the
/// highlight morphs between rows as the selection cycles. On earlier systems it falls back to the
/// classic accent-color highlight (the panel supplies an `NSVisualEffectView` backing there).
struct SwitcherView: View {

    @ObservedObject var model: SwitcherViewModel

    @Namespace private var glassNamespace

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer {
                content
                    .glassEffect(.clear, in: .rect(cornerRadius: 16))
            }
        } else {
            content
        }
    }

    private var content: some View {
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
                row(title: item.title, selected: index == model.selection)
            }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
    }

    @ViewBuilder
    private func row(title: String, selected: Bool) -> some View {
        let label =
            Text(title.isEmpty ? "Untitled" : title)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

        if #available(macOS 26.0, *) {
            // Only the selected row carries a glass highlight; non-selected rows are plain text.
            // Because exactly one element ever holds the "selection" glassEffectID, the highlight
            // morphs from row to row as the selection moves.
            if selected {
                // The glass tint alone is too faint to read as "selected" over busy backdrops,
                // so back it with a translucent accent fill (close to the native switcher's
                // highlight). The shared glassEffectID keeps the highlight morphing between rows.
                label
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.5))
                    )
                    .glassEffect(.regular.tint(.accentColor), in: .rect(cornerRadius: 6))
                    .glassEffectID("selection", in: glassNamespace)
            } else {
                label
            }
        } else {
            label
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected ? Color.accentColor : Color.clear)
                )
        }
    }

}
