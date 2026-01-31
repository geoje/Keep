import SwiftUI
import WidgetKit

struct NoteWidget: Widget {
  let kind: String = "NoteWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      NoteWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}
