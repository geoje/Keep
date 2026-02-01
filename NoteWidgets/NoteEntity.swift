import AppIntents
import WidgetKit

struct NoteEntity: AppEntity {
  typealias ID = String

  let id: String
  let email: String
  let title: String
  let text: String
  let uncheckedItems: [String]
  let checkedItems: [String]

  init(
    id: String, email: String, title: String = "", text: String = "", uncheckedItems: [String] = [],
    checkedItems: [String] = []
  ) {
    self.id = id
    self.email = email
    self.title = title
    self.text = text
    self.uncheckedItems = uncheckedItems
    self.checkedItems = checkedItems
  }

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Note"

  var displayRepresentation: DisplayRepresentation {
    if email.isEmpty {
      let title = LocalizedStringResource(stringLiteral: "--- \(id) ---")
      return DisplayRepresentation(title: title)
    }

    let subtitle: String
    if !uncheckedItems.isEmpty || !checkedItems.isEmpty {
      var parts: [String] = []
      if !uncheckedItems.isEmpty {
        parts.append("□ \(uncheckedItems[0])")
        if uncheckedItems.count > 1 {
          parts.append(
            "+ \(uncheckedItems.count - 1) unchecked item\(uncheckedItems.count - 1 > 1 ? "s" : "")"
          )
        }
      }
      if !checkedItems.isEmpty {
        parts.append("+ \(checkedItems.count) checked item\(checkedItems.count > 1 ? "s" : "")")
      }
      subtitle = parts.joined(separator: "\n")
    } else {
      subtitle = text
    }
    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title.isEmpty ? "Untitled" : title),
      subtitle: LocalizedStringResource(stringLiteral: subtitle),
      image: DisplayRepresentation.Image(systemName: "document"))
  }

  static var defaultQuery: NoteEntitiesProvider {
    NoteEntitiesProvider()
  }
}
