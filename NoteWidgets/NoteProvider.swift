import SwiftData
import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    return NoteEntry(
      date: Date(), configuration: NoteAppIntent(),
      note: NoteEntity(
        id: "", email: "", title: "Sample Note",
        text: "This is a sample note for the widget preview."))
  }

  func snapshot(for configuration: NoteAppIntent, in context: Context) async -> NoteEntry {
    let note =
      configuration.selectedNote != nil ? configuration.selectedNote : await getDefaultNote()
    return NoteEntry(date: Date(), configuration: configuration, note: note)
  }

  func timeline(for configuration: NoteAppIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    let note =
      configuration.selectedNote != nil ? configuration.selectedNote : await getDefaultNote()
    let entry = NoteEntry(date: Date(), configuration: configuration, note: note)
    return Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 900)))
  }

  private func getDefaultNote() async -> NoteEntity? {
    let modelContainer = try? ModelContainer(for: Account.self, Note.self)
    if let modelContainer {
      let actor = NoteModelActor(modelContainer: modelContainer)
      let entities = try? await actor.fetchNotes()
      return entities?.first(where: { !$0.email.isEmpty })
    }
    return nil
  }
}
