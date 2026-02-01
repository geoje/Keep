import AppIntents
import SwiftData
import WidgetKit

actor NoteModelActor: ModelActor {
  let modelContainer: ModelContainer
  let modelContext: ModelContext
  let modelExecutor: any ModelExecutor

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  }

  func fetchNotes() throws -> [NoteEntity] {
    let accountDescriptor = FetchDescriptor<Account>()
    let noteDescriptor = FetchDescriptor<Note>()
    let accounts = try modelContext.fetch(accountDescriptor)
    let allNotes = try modelContext.fetch(noteDescriptor)
    let noteService = NoteService()

    var entities: [NoteEntity] = []
    for account in accounts {
      let rootNotes = noteService.getRootNotes(notes: allNotes, email: account.email)
      entities.append(NoteEntity(id: account.email, email: ""))
      entities.append(
        contentsOf: rootNotes.map {
          let uncheckedItems = noteService.parseUncheckedItems(notes: allNotes, rootNoteId: $0.id)
          let checkedItems = noteService.parseCheckedItems(notes: allNotes, rootNoteId: $0.id)

          if $0.type == "LIST" {
            return NoteEntity(
              id: $0.id, email: $0.email, color: $0.color, title: $0.title,
              uncheckedItems: uncheckedItems,
              checkedItems: checkedItems)
          } else {
            return NoteEntity(
              id: $0.id, email: $0.email, color: $0.color, title: $0.title,
              text: uncheckedItems.joined(separator: "\n"))
          }
        })
    }

    return entities
  }
}
