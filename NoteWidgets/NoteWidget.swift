import SwiftUI
import WidgetKit

struct NoteWidget: Widget {
  let kind: String = "NoteWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: NoteAppIntent.self, provider: NoteProvider()) {
      entry in
      NoteWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("DisplayName")
    .description("Description")
  }
}
