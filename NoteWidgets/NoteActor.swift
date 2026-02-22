import AppIntents
import SwiftData
import WidgetKit

actor NoteActor: ModelActor {
  let modelContainer: ModelContainer
  let modelContext: ModelContext
  let modelExecutor: ModelExecutor
  let noteService = NoteService()

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  }

  func fetchNotes() throws -> [NoteEntity] {
    let accountDescriptor = FetchDescriptor<Account>()
    let noteDescriptor = FetchDescriptor<Note>()
    let accounts = try modelContext.fetch(accountDescriptor)
    let notes = try modelContext.fetch(noteDescriptor)

    var entities: [NoteEntity] = []
    for account in accounts {
      let rootNotes = noteService.getRootNotes(notes: notes, email: account.email)
      entities.append(NoteEntity(id: account.email, email: ""))
      entities.append(
        contentsOf: rootNotes.map {
          buildEntity(
            note: $0,
            uncheckedItems: noteService.parseUncheckedItems(notes: notes, rootNoteId: $0.id),
            checkedItems: noteService.parseCheckedItems(notes: notes, rootNoteId: $0.id)
          )
        })
    }
    return entities
  }

  private func buildEntity(note: Note, uncheckedItems: [String], checkedItems: [String])
    -> NoteEntity
  {
    if note.type == "LIST" {
      return NoteEntity(
        id: note.id, email: note.email, color: note.color, title: note.title,
        uncheckedItems: uncheckedItems,
        checkedItems: checkedItems, type: note.type, serverId: note.serverId)
    } else {
      return NoteEntity(
        id: note.id, email: note.email, color: note.color, title: note.title,
        text: uncheckedItems.joined(separator: "\n"), type: note.type, serverId: note.serverId)
    }
  }
}
