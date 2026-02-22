import AppIntents
import SwiftData
import WidgetKit

struct NoteQuery: EntityQuery {

  func suggestedEntities() async throws -> IntentItemCollection<NoteEntity> {
    var sections: [IntentItemSection<NoteEntity>] = []

    let actor = NoteActor(modelContainer: ModelContainer.shared)
    let grouped = Dictionary(grouping: try await actor.fetchNotes(), by: { $0.email })
    for (email, notes) in grouped {
      sections.append(
        IntentItemSection<NoteEntity>(
          LocalizedStringResource(stringLiteral: email),
          items: notes.map { IntentItem($0) }
        )
      )
    }

    return IntentItemCollection(sections: sections)
  }

  func entities(for identifiers: [String]) async throws -> [NoteEntity] {
    let actor = NoteActor(modelContainer: ModelContainer.shared)
    return try await actor.fetchNotes().filter { identifiers.contains($0.id) }
  }
}
