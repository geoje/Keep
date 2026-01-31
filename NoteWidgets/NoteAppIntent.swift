import AppIntents
import SwiftData
import WidgetKit

struct NoteEntity: AppEntity {
  typealias ID = String

  let id: String
  let title: String
  let subtitle: String
  let email: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Note"

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: "[\(email)] \(title)"),
      subtitle: LocalizedStringResource(stringLiteral: subtitle))
  }

  static var defaultQuery: NoteEntitiesProvider {
    NoteEntitiesProvider()
  }
}

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
    return notes.map { note in
      NoteEntity(id: note.id, title: note.title, subtitle: note.text, email: note.email)
    }
  }
}

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

struct NoteAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Note" }
  static var description: IntentDescription { "Get quick access to one of your notes" }

  @Parameter(
    title: LocalizedStringResource("Selected Note"), optionsProvider: NoteEntitiesProvider())
  var selectedNote: NoteEntity?
}
