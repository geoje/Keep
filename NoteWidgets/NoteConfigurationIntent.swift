import AppIntents
import SwiftData
import WidgetKit

struct NoteConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Note" }
  static var description: IntentDescription {
    "Get quick access to one of your notes"
  }

  @Parameter(
    title: LocalizedStringResource("Note"),
    optionsProvider: NoteQuery())
  var selectedNote: NoteEntity?
}
