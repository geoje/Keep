import SwiftData
import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    return NoteEntry(
      date: Date(), configuration: NoteAppIntent(),
      note: NoteEntity(
        id: "", email: "", title: "Sample Note",
        text: "This is a sample note for the widget preview"))
  }

  func snapshot(for configuration: NoteAppIntent, in context: Context) async -> NoteEntry {
    let note =
      configuration.selectedNote != nil ? configuration.selectedNote : await getDefaultNote()
    return NoteEntry(date: Date(), configuration: configuration, note: note)
  }

  func timeline(for configuration: NoteAppIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    if let selectedNote = configuration.selectedNote, !selectedNote.email.isEmpty {
      let actor = NoteModelActor(modelContainer: ModelContainer.shared)
      try? await actor.syncNotesForAccount(email: selectedNote.email)
    }

    let note: NoteEntity?
    if let selectedNote = configuration.selectedNote {
      let provider = NoteEntitiesProvider()
      let entities = try? await provider.entities(for: [selectedNote.id])
      note = entities?.first
    } else {
      note = await getDefaultNote()
    }

    let entry = NoteEntry(
      date: Date(), configuration: configuration,
      note: note ?? NoteEntity(id: "", email: "", title: "No Note", text: ""))
    return Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 900)))
  }

  private func getDefaultNote() async -> NoteEntity? {
    let provider = NoteEntitiesProvider()
    let entities = try? await provider.suggestedEntities()
    return entities?.first(where: { !$0.email.isEmpty })
  }
}
