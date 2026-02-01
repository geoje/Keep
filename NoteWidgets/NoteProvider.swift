import SwiftData
import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    return NoteEntry(date: Date(), configuration: NoteAppIntent())
  }

  func snapshot(for configuration: NoteAppIntent, in context: Context) async -> NoteEntry {
    let finalConfiguration = await configurationWithDefaultNote(configuration)
    return NoteEntry(date: Date(), configuration: finalConfiguration)
  }

  func timeline(for configuration: NoteAppIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    let finalConfiguration = await configurationWithDefaultNote(configuration)
    let entry = NoteEntry(date: Date(), configuration: finalConfiguration)
    return Timeline(entries: [entry], policy: .never)
  }

  private func configurationWithDefaultNote(_ configuration: NoteAppIntent) async -> NoteAppIntent {
    var config = configuration
    if config.selectedNote == nil {
      let modelContainer = try? ModelContainer(for: Account.self, Note.self)
      if let modelContainer {
        let actor = NoteModelActor(modelContainer: modelContainer)
        let entities = try? await actor.fetchNotes()
        if let firstNote = entities?.first(where: { !$0.id.contains("@") }) {
          config.selectedNote = firstNote
        }
      }
    }
    return config
  }
}
