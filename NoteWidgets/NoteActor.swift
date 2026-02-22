import AppIntents
import WidgetKit

actor NoteActor {
  let noteService = NoteService.shared
  let apiClient = LocalApiClient.shared

  init() {}

  func fetchNotes() async throws -> [NoteEntity] {
    do {
      let notes = try await apiClient.fetchNotes()
      let emails = Set(notes.map { $0.email })
      var entities: [NoteEntity] = []
      for email in emails {
        let rootNotes = noteService.getRootNotes(notes: notes, email: email)
        entities.append(
          contentsOf: rootNotes.map { rootNote in
            if !rootNote.checkedCheckboxesCount.isEmpty {
              return buildEntityItself(rootNote: rootNote)
            } else {
              return buildEntityWithChildren(note: rootNote, notes: notes)
            }
          })
      }
      return entities
    } catch _ as URLError {
      return [buildErrorNoteEntity()]
    }
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

  private func buildErrorNoteEntity() -> NoteEntity {
    return NoteEntity(
      id: UUID().uuidString,
      email: "error@keep.local",
      color: "",
      title: "Error",
      text:
        "Cannot connect to the Keep local server.\n"
        + "Please make sure Keep is running in the Menubar.",
      type: "TEXT",
      serverId: ""
    )
  }
}
