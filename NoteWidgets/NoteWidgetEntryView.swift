import SwiftUI
import WidgetKit

struct NoteWidgetEntryView: View {
  var entry: NoteEntry

  var body: some View {
    VStack(alignment: .leading) {
      if let selectedNote = entry.configuration.selectedNote {
        VStack(alignment: .leading) {
          Text("[\(selectedNote.email)] \(selectedNote.title)")
            .font(.headline)
          Text(selectedNote.subtitle)
            .font(.body)
        }
        .padding()
      } else {
        ForEach(entry.notes, id: \.id) { note in
          VStack(alignment: .leading) {
            Text(note.title)
              .font(.headline)
            Text(note.text)
              .font(.body)
          }
          .padding(.bottom, 4)
        }
        .padding()
      }
    }
  }
}
