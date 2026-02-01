import SwiftUI
import WidgetKit

struct NoteWidgetEntryView: View {
  var entry: NoteEntry

  var body: some View {
    if let selectedNote = entry.configuration.selectedNote {
      VStack(alignment: .leading) {
        Text(selectedNote.title)
          .font(.headline)
        Text(selectedNote.text)
          .font(.body)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      Text("No selected note")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
