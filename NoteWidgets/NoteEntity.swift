import AppIntents
import SwiftData
import WidgetKit

struct NoteEntity: AppEntity {
  typealias ID = String

  let id: String
  let title: String
  let text: String
  let uncheckedItems: [String]
  let checkedItems: [String]

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Note"

  var displayRepresentation: DisplayRepresentation {
    let subtitleText: String
    if !uncheckedItems.isEmpty || !checkedItems.isEmpty {
      var parts: [String] = []
      if !uncheckedItems.isEmpty {
        parts.append(uncheckedItems.map { "□ \($0)" }.joined(separator: "\n"))
      }
      if !checkedItems.isEmpty {
        parts.append(checkedItems.map { "☑ \($0)" }.joined(separator: "\n"))
      }
      subtitleText = parts.joined(separator: "\n")
    } else {
      subtitleText = text
    }
    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title),
      subtitle: LocalizedStringResource(stringLiteral: subtitleText)
    )
  }

  static var defaultQuery: NoteEntitiesProvider {
    NoteEntitiesProvider()
  }
}
