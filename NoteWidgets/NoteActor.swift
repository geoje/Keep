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
      entities.append(
        contentsOf: rootNotes.map { rootNote in
          if !rootNote.checkedCheckboxesCount.isEmpty {
            return buildEntityItself(rootNote: rootNote)
          } else {
            return buildEntityWithChildren(note: rootNote, notes: notes)
          }
        }
      )
    }
    return entities
  }

  private func buildEntityItself(rootNote: Note) -> NoteEntity {
    if rootNote.type == "LIST" {
      let items = rootNote.indexableText.components(separatedBy: "\n")
      let checkedCount = max(0, Int(rootNote.checkedCheckboxesCount) ?? 0)
      let checkedItems = Array(items.suffix(checkedCount))
      let uncheckedItems = Array(items.prefix(items.count - checkedCount))

      return NoteEntity(
        id: rootNote.id,
        email: rootNote.email,
        color: rootNote.color,
        title: rootNote.title,
        uncheckedItems: uncheckedItems,
        checkedItems: checkedItems,
        type: rootNote.type,
        serverId: rootNote.serverId
      )
    }

    return NoteEntity(
      id: rootNote.id,
      email: rootNote.email,
      color: rootNote.color,
      title: rootNote.title,
      text: rootNote.indexableText,
      type: rootNote.type,
      serverId: rootNote.serverId
    )

  }

  private func buildEntityWithChildren(note: Note, notes: [Note]) -> NoteEntity {
    var uncheckedItems: [String] = []
    var checkedItems: [String] = []
    for n in notes {
      if n.parentId == note.id {
        if n.checked {
          checkedItems.append(n.text)
        } else {
          uncheckedItems.append(n.text)
        }
      }
    }

    if note.type == "LIST" {
      return NoteEntity(
        id: note.id,
        email: note.email,
        color: note.color,
        title: note.title,
        uncheckedItems: uncheckedItems,
        checkedItems: checkedItems,
        type: note.type,
        serverId: note.serverId
      )
    }

    return NoteEntity(
      id: note.id,
      email: note.email,
      color: note.color,
      title: note.title,
      text: uncheckedItems.joined(separator: "\n"),
      type: note.type,
      serverId: note.serverId
    )
  }
}
