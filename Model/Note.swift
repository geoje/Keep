import Foundation
import SwiftData

@Model
final class Note {
  var email: String = ""
  var id: String = ""
  var kind: String = ""
  var parentId: String = ""
  var type: String = ""
  var trashed: String = ""
  var title: String = ""
  var text: String = ""
  var isArchived: Bool = false
  var color: String = ""
  var sortValue: String = ""
  var checked: Bool = false

  init(
    email: String = "",
    id: String = "",
    kind: String = "",
    parentId: String = "",
    type: String = "",
    trashed: String = "",
    title: String = "",
    text: String = "",
    isArchived: Bool = false,
    color: String = "",
    sortValue: String = "",
    checked: Bool = false
  ) {
    self.email = email
    self.id = id
    self.kind = kind
    self.parentId = parentId
    self.type = type
    self.trashed = trashed
    self.title = title
    self.text = text
    self.isArchived = isArchived
    self.color = color
    self.sortValue = sortValue
    self.checked = checked
  }

  static func from(dict: [String: Any], email: String) throws -> Note {
    let timestampsDict = (dict["timestamps"] as? [String: Any]) ?? [:]

    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let trashedString = timestampsDict["trashed"] as? String
    let trashed = trashedString ?? ""

    return Note(
      email: email,
      id: dict["id"] as? String ?? "",
      kind: dict["kind"] as? String ?? "",
      parentId: dict["parentId"] as? String ?? "",
      type: dict["type"] as? String ?? "",
      trashed: trashed,
      title: dict["title"] as? String ?? "",
      text: dict["text"] as? String ?? "",
      isArchived: dict["isArchived"] as? Bool ?? false,
      color: dict["color"] as? String ?? "",
      sortValue: dict["sortValue"] as? String ?? "",
      checked: dict["checked"] as? Bool ?? false
    )
  }
}
