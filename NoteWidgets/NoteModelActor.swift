import AppIntents
import SwiftData
import WidgetKit

actor NoteModelActor: ModelActor {
  let modelContainer: ModelContainer
  let modelExecutor: any ModelExecutor
  let modelContext: ModelContext

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  }

  func fetchNotes() throws -> [NoteEntity] {
    let descriptor = FetchDescriptor<Note>()
    let notes = try modelContext.fetch(descriptor)
    return notes.filter { $0.parentId == "root" }.map { note in
      NoteEntity(id: note.id, title: note.title, subtitle: note.text, email: note.email)
    }
  }
}
