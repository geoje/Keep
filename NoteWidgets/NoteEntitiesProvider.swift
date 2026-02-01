import AppIntents
import SwiftData
import WidgetKit

struct NoteEntitiesProvider: EntityQuery {
  typealias Entity = NoteEntity
  typealias Result = [NoteEntity]

  func results() async throws -> [NoteEntity] {
    let actor = NoteModelActor(modelContainer: ModelContainer.shared)
    return try await actor.fetchNotes()
  }

  func suggestedEntities() async throws -> [NoteEntity] {
    return try await results()
  }

  func entities(for identifiers: [String]) async throws -> [NoteEntity] {
    let all = try await results()
    return all.filter { identifiers.contains($0.id) }
  }
}
