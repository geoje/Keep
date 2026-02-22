import AppIntents
import SwiftUI
import WidgetKit

struct NoteWidget: Widget {
  let kind: String = "NoteWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: NoteConfigurationIntent.self, provider: NoteProvider()
    ) {
      entry in
      NoteView(entry: entry)
    }
    .configurationDisplayName(NoteConfigurationIntent.title)
    .description(NoteConfigurationIntent.description.descriptionText)
  }
}
