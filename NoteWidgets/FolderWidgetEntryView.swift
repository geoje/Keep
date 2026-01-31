import SwiftUI
import WidgetKit

struct FolderWidgetEntryView: View {
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
