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

struct FolderWidget: Widget {
  let kind: String = "FolderWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      FolderWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}
