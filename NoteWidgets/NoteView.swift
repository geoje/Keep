import SwiftUI
import WidgetKit

struct NoteView: View {
  @Environment(\.colorScheme) var colorScheme
  var entry: NoteEntry

  var body: some View {
    ZStack {
      if let entity = entry.entity {
        noteContentView(for: entity)
          .widgetURL(URL(string: "https://keep.google.com/#\(entity.type)/\(entity.serverId)"))
      } else {
        Text("No selected note")
          .font(.body)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .widgetURL(URL(string: "https://keep.google.com"))
      }
    }
    .containerBackground(for: .widget) {
      NoteService.shared.noteColor(for: entry.entity?.color ?? "", colorScheme: colorScheme)
    }
  }

  private func noteContentView(for entity: NoteEntity) -> some View {
    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 4) {
        if !entity.title.isEmpty {
          Text(entity.title)
            .font(.headline)
        }
        if entity.uncheckedItems.isEmpty && entity.checkedItems.isEmpty {
          Text(entity.text)
            .font(.body)
        } else {
          if !entity.uncheckedItems.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              ForEach(entity.uncheckedItems.indices, id: \.self) { index in
                let item = entity.uncheckedItems[index]
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
          if !entity.checkedItems.isEmpty {
            Text(
              "+ \(entity.checkedItems.count) checked item\(entity.checkedItems.count > 1 ? "s" : "")"
            )
            .font(.body)
            .foregroundColor(.secondary)
          }
        }
      }
      .foregroundColor(.primary)
      .frame(maxWidth: .infinity, maxHeight: geo.size.height, alignment: .topLeading)
    }
  }

}
