import SwiftUI
import WidgetKit
import AppIntents

struct NoteWidget: Widget {
  let kind: String = "NoteWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: NoteAppIntent.self, provider: NoteProvider()) {
      entry in
      NoteWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(NoteAppIntent.title)
    .description(NoteAppIntent.description.descriptionText)
  }
}
