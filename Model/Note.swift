import Foundation
import SwiftData

@Model
final class Note {
  var email: String = ""
  var id: String = ""
  var serverId: String = ""
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
  var indexableText: String = ""
  var checkedCheckboxesCount: String = ""

  init(
    email: String = "",
    id: String = "",
    serverId: String = "",
    kind: String = "",
    parentId: String = "",
    type: String = "",
    trashed: String = "",
    title: String = "",
    text: String = "",
    isArchived: Bool = false,
    color: String = "",
    sortValue: String = "",
    checked: Bool = false,
    indexableText: String = "",
    checkedCheckboxesCount: String = ""
  ) {
    self.email = email
    self.id = id
    self.serverId = serverId
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
    self.indexableText = indexableText
    self.checkedCheckboxesCount = checkedCheckboxesCount
  }

  static func from(dict: [String: Any], email: String) throws -> Note {
    let timestampsDict = (dict["timestamps"] as? [String: Any]) ?? [:]
    let previewDataDict = (dict["previewData"] as? [String: Any]) ?? [:]

    return Note(
      email: email,
      id: dict["id"] as? String ?? "",
      serverId: dict["serverId"] as? String ?? "",
      kind: dict["kind"] as? String ?? "",
      parentId: dict["parentId"] as? String ?? "",
      type: dict["type"] as? String ?? "",
      trashed: timestampsDict["trashed"] as? String ?? "",
      title: dict["title"] as? String ?? "",
      text: dict["text"] as? String ?? "",
      isArchived: dict["isArchived"] as? Bool ?? false,
      color: dict["color"] as? String ?? "",
      sortValue: dict["sortValue"] as? String ?? "",
      checked: dict["checked"] as? Bool ?? false,
      indexableText: dict["indexableText"] as? String ?? "",
      checkedCheckboxesCount: previewDataDict["checkedCheckboxesCount"] as? String ?? ""
    )
  }

  func toDictionary() -> [String: Any] {
    return [
      "email": email,
      "id": id,
      "serverId": serverId,
      "kind": kind,
      "parentId": parentId,
      "type": type,
      "trashed": trashed,
      "title": title,
      "text": text,
      "isArchived": isArchived,
      "color": color,
      "sortValue": sortValue,
      "checked": checked,
      "indexableText": indexableText,
      "checkedCheckboxesCount": checkedCheckboxesCount,
    ]
  }
}
