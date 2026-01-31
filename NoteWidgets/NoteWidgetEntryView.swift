import SwiftUI
import WidgetKit

struct NoteWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      Text("Time:")
      Text(entry.date, style: .time)

      Text("Favorite Emoji:")
      Text(entry.configuration.favoriteEmoji)
    }
  }
}
