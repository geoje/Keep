import AppIntents
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

struct NoteEntitiesProvider: EntityQuery {
  typealias Entity = NoteEntity
  typealias Result = [NoteEntity]

  func results() async throws -> [NoteEntity] {
    return [
      NoteEntity(id: "1", title: "NoteTitle1", subtitle: "NoteText1", email: "boy@gmail.com"),
      NoteEntity(id: "2", title: "NoteTitle2", subtitle: "NoteText2", email: "boy@gmail.com"),
      NoteEntity(id: "3", title: "NoteTitle3", subtitle: "NoteText3", email: "girl@gmail.com"),
      NoteEntity(id: "4", title: "NoteTitle4", subtitle: "NoteText4", email: "girl@gmail.com"),
    ]
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

  @Parameter(title: LocalizedStringResource("Selected Account"))
  var selectedAccount: String?

  @Parameter(
    title: LocalizedStringResource("Selected Note"), optionsProvider: NoteEntitiesProvider())
  var selectedNote: NoteEntity?
}
