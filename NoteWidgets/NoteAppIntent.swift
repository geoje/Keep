import AppIntents
import SwiftData
import WidgetKit

struct NoteAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Note" }
  static var description: IntentDescription { "Get quick access to one of your notes. If notes are not visible, open the main app and tap an account to sync." }

  @Parameter(
    title: LocalizedStringResource("Note"), optionsProvider: NoteEntitiesProvider())
  var selectedNote: NoteEntity?
}
