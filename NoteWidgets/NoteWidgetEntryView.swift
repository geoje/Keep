import SwiftUI
import WidgetKit

struct NoteWidgetEntryView: View {
  var entry: NoteEntry

  var body: some View {
    if let note = entry.note {
      VStack(alignment: .leading, spacing: 4) {
        if !note.title.isEmpty {
          Text(note.title)
            .font(.headline)
        }
        if note.uncheckedItems.isEmpty && note.checkedItems.isEmpty {
          Text(note.text)
            .font(.body)
        } else {
          if !note.uncheckedItems.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              ForEach(note.uncheckedItems, id: \.self) { item in
                HStack(spacing: 4) {
                  Image(systemName: "square")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(0.4)
                  Text(item)
                    .font(.body)
                }
              }
            }
          }
          if !note.checkedItems.isEmpty {
            Text(
              "+ \(note.checkedItems.count) checked item\(note.checkedItems.count > 1 ? "s" : "")"
            )
            .font(.body)
            .foregroundColor(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      Text("No selected note")
        .font(.body)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
