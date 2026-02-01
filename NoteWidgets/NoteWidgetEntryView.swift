import SwiftUI
import WidgetKit

struct NoteWidgetEntryView: View {
  var entry: NoteEntry

  var body: some View {
    if let note = entry.note {
      VStack(alignment: .leading, spacing: 4) {
        Text(note.title)
          .font(.headline)
        Text(note.text)
          .font(.body)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      Text("No selected note")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
