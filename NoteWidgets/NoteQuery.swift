import AppIntents
import SwiftData
import WidgetKit

struct NoteQuery: EntityStringQuery {
  func suggestedEntities() async throws -> [NoteEntity] {
    let actor = NoteActor(modelContainer: ModelContainer.shared)
    return try await actor.fetchNotes()
  }

  func entities(matching string: String) async throws -> [NoteEntity] {
    let search = string.lowercased()

    return try await suggestedEntities().filter { entity in
      entity.email.lowercased().contains(search)
        || entity.title.lowercased().contains(search)
        || entity.text.lowercased().contains(search)
        || entity.uncheckedItems.contains(where: { $0.lowercased().contains(search) })
        || entity.checkedItems.contains(where: { $0.lowercased().contains(search) })
    }
  }

  func entities(for identifiers: [String]) async throws -> [NoteEntity] {
    return try await suggestedEntities().filter { identifiers.contains($0.id) }
  }
}
