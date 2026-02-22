import AppIntents
import SwiftData
import WidgetKit

struct NoteQuery: EntityQuery {
  func suggestedEntities() async throws -> [NoteEntity] {
    let actor = NoteActor(modelContainer: ModelContainer.shared)
    return try await actor.fetchNotes()
  }

  // func results(search: String? = nil) async throws -> [NoteEntity] {
  //   let entities = try await suggestedEntities()
  //   guard let search = search, !search.isEmpty else {
  //     return entities
  //   }

  //   let lowercasedSearch = search.lowercased()
  //   return entities.filter { entity in
  //     if entity.email.isEmpty {
  //       return true
  //     }
  //     return entity.email.lowercased().contains(lowercasedSearch)
  //       || entity.title.lowercased().contains(lowercasedSearch)
  //       || entity.text.lowercased().contains(lowercasedSearch)
  //       || entity.uncheckedItems.contains(where: { $0.lowercased().contains(lowercasedSearch) })
  //       || entity.checkedItems.contains(where: { $0.lowercased().contains(lowercasedSearch) })
  //   }
  // }

  func entities(for identifiers: [String]) async throws -> [NoteEntity] {
    let all = try await results()
    return all.filter { identifiers.contains($0.id) }
  }
}
