import AppIntents
import WidgetKit

struct NoteEntity: AppEntity {
  let id: String
  let email: String
  let color: String
  let title: String
  let text: String
  let uncheckedItems: [String]
  let checkedItems: [String]
  let type: String
  let serverId: String

  typealias ID = String
  static let sampleEntity = NoteEntity(
    id: "", email: "", title: "Sample Note",
    text: "This is a sample note for the widget preview"
  )

  init(
    id: String, email: String, color: String = "", title: String = "", text: String = "",
    uncheckedItems: [String] = [],
    checkedItems: [String] = [], type: String = "", serverId: String = ""
  ) {
    self.id = id
    self.email = email
    self.color = color
    self.title = title
    self.text = text
    self.uncheckedItems = uncheckedItems
    self.checkedItems = checkedItems
    self.type = type
    self.serverId = serverId
  }

  static var defaultQuery: NoteQuery { NoteQuery() }
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Note"

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: buildTitle(),
      subtitle: buildSubtitle(),
      image: DisplayRepresentation.Image(systemName: "document")
    )
  }

  private func buildTitle() -> LocalizedStringResource {
    if email.isEmpty {
      return LocalizedStringResource(stringLiteral: "--- \(id) ---")
    }
    return LocalizedStringResource(
      stringLiteral: (title.isEmpty ? "Untitled" : title).truncated(to: 30))
  }

  private func buildSubtitle() -> LocalizedStringResource {
    if email.isEmpty {
      return LocalizedStringResource(stringLiteral: "")
    }
    let subtitle: String
    if !uncheckedItems.isEmpty || !checkedItems.isEmpty {
      var parts: [String] = []
      if !uncheckedItems.isEmpty {
        parts.append("□ \(uncheckedItems[0].truncated(to: 30))")
        if uncheckedItems.count > 1 {
          let extraUnchecked = uncheckedItems.count - 1
          let itemWord = extraUnchecked == 1 ? "item" : "items"
          parts.append("+ \(extraUnchecked) unchecked \(itemWord)")
        }
      }
      if !checkedItems.isEmpty {
        let itemWord = checkedItems.count == 1 ? "item" : "items"
        parts.append("+ \(checkedItems.count) checked \(itemWord)")
      }
      subtitle = parts.joined(separator: "\n")
    } else {
      let lines = text.components(separatedBy: "\n")
      if lines.count <= 2 {
        subtitle = lines.map { $0.truncated(to: 30) }.joined(separator: "\n")
      } else {
        let firstTwo = lines.prefix(2).map { $0.truncated(to: 30) }.joined(separator: "\n")
        let extraLines = lines.count - 2
        let lineWord = extraLines == 1 ? "line" : "lines"
        subtitle = firstTwo + "\n+ \(extraLines) \(lineWord)"
      }
    }
    return LocalizedStringResource(stringLiteral: subtitle)
  }
}

extension String {
  func truncated(to length: Int) -> String {
    if self.count <= length {
      return self
    } else {
      return String(self.prefix(length - 3)) + "..."
    }
  }
}
