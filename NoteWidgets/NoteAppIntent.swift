import AppIntents
import SwiftData
import WidgetKit

struct NoteAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Note" }
  static var description: IntentDescription { "Get quick access to one of your notes" }

  @Parameter(
    title: LocalizedStringResource("Note"), optionsProvider: NoteEntitiesProvider())
  var selectedNote: NoteEntity?
}
