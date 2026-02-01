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
    let accountDescriptor = FetchDescriptor<Account>()
    let noteDescriptor = FetchDescriptor<Note>()
    let accounts = try modelContext.fetch(accountDescriptor)
    let allNotes = try modelContext.fetch(noteDescriptor)
    let noteService = NoteService()

    var entities: [NoteEntity] = []
    for account in accounts {
      entities.append(
        NoteEntity(
          id: account.email, title: "", text: account.email, uncheckedItems: [], checkedItems: []))
      let rootNotes = noteService.getRootNotes(notes: allNotes, email: account.email)
      entities.append(
        contentsOf: rootNotes.map {
          let uncheckedItems = noteService.parseUncheckedItems(notes: allNotes, rootNoteId: $0.id)
          let checkedItems = noteService.parseCheckedItems(notes: allNotes, rootNoteId: $0.id)
          return NoteEntity(
            id: $0.id, title: $0.title, text: $0.text, uncheckedItems: uncheckedItems,
            checkedItems: checkedItems)
        })
    }

    return entities
  }
}
