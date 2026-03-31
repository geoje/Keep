import SwiftUI

struct NoteCardView: View {
  let uncheckedItems: [String]
  let checkedItems: [String]
  let textContent: String
  let note: Note

  @Environment(\.colorScheme) var colorScheme
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if !note.title.isEmpty {
        Text(note.title)
          .font(.headline)
          .foregroundColor(.primary)
      }
      if uncheckedItems.isEmpty && checkedItems.isEmpty {
        if !textContent.isEmpty {
          Text(textContent)
            .font(.body)
            .foregroundColor(.primary)
        }
      } else {
        if !uncheckedItems.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(uncheckedItems.indices, id: \.self) { index in
              HStack(spacing: 4) {
                Image(systemName: "square")
                  .font(.body)
                  .foregroundColor(.secondary)
                  .opacity(0.4)
                Text(uncheckedItems[index])
                  .font(.body)
                  .foregroundColor(.primary)
              }
            }
          }
        }
        if !checkedItems.isEmpty {
          Text("+ \(checkedItems.count) checked item\(checkedItems.count > 1 ? "s" : "")")
            .font(.body)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(10)
    .background(NoteService.shared.noteColor(for: note.color, colorScheme: colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .shadow(
      color: Color.primary.opacity(isHovered ? 0.4 : 0), radius: isHovered ? 1 : 0,
      y: isHovered ? 1 : 0
    )
    .animation(.easeInOut(duration: 0.1), value: isHovered)
    .onHover { isHovered = $0 }
  }
}
