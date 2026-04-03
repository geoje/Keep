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
  var trashedAt: String = ""
  var deletedAt: String = ""
  var title: String = ""
  var text: String = ""
  var isArchived: Bool = false
  var color: String = ""
  var sortValue: String = ""
  var checked: Bool = false
  var indexableText: String = ""
  var checkedCheckboxesCount: String = ""
  var isDirty: Bool = false
  var serverRevision: String = ""
  var createdAt: String = ""

  init(
    email: String = "",
    id: String = "",
    serverId: String = "",
    kind: String = "",
    parentId: String = "",
    type: String = "",
    trashedAt: String = "",
    deletedAt: String = "",
    title: String = "",
    text: String = "",
    isArchived: Bool = false,
    color: String = "",
    sortValue: String = "",
    checked: Bool = false,
    indexableText: String = "",
    checkedCheckboxesCount: String = "",
    serverRevision: String = "",
    createdAt: String = ""
  ) {
    self.email = email
    self.id = id
    self.serverId = serverId
    self.kind = kind
    self.parentId = parentId
    self.type = type
    self.trashedAt = trashedAt
    self.deletedAt = deletedAt
    self.title = title
    self.text = text
    self.isArchived = isArchived
    self.color = color
    self.sortValue = sortValue
    self.checked = checked
    self.indexableText = indexableText
    self.checkedCheckboxesCount = checkedCheckboxesCount
    self.serverRevision = serverRevision
    self.createdAt = createdAt
  }

  static func decode(dict: [String: Any]) -> Note {
    return Note(
      email: dict["email"] as? String ?? "",
      id: dict["id"] as? String ?? "",
      serverId: dict["serverId"] as? String ?? "",
      kind: dict["kind"] as? String ?? "",
      parentId: dict["parentId"] as? String ?? "",
      type: dict["type"] as? String ?? "",
      trashedAt: dict["trashedAt"] as? String ?? "",
      deletedAt: dict["deletedAt"] as? String ?? "",
      title: dict["title"] as? String ?? "",
      text: dict["text"] as? String ?? "",
      isArchived: dict["isArchived"] as? Bool ?? false,
      color: dict["color"] as? String ?? "",
      sortValue: dict["sortValue"] as? String ?? "",
      checked: dict["checked"] as? Bool ?? false,
      indexableText: dict["indexableText"] as? String ?? "",
      checkedCheckboxesCount: dict["checkedCheckboxesCount"] as? String ?? "",
      serverRevision: dict["serverRevision"] as? String ?? "",
      createdAt: dict["createdAt"] as? String ?? ""
    )
  }

  func update(from dict: [String: Any]) {
    let timestampsDict = (dict["timestamps"] as? [String: Any]) ?? [:]
    let previewDataDict = (dict["previewData"] as? [String: Any]) ?? [:]

    if let v = dict["serverId"] as? String { serverId = v }
    if let v = dict["parentId"] as? String { parentId = v }
    if let v = dict["type"] as? String { type = v }
    if let v = dict["title"] as? String { title = v }
    if let v = dict["text"] as? String { text = v }
    if let v = dict["color"] as? String { color = v }
    if let v = dict["isArchived"] as? Bool { isArchived = v }
    if let v = dict["sortValue"] as? String { sortValue = v }
    if let v = dict["checked"] as? Bool { checked = v }
    if let v = timestampsDict["trashed"] as? String { trashedAt = v }
    if let v = timestampsDict["deleted"] as? String { deletedAt = v }
    if let v = timestampsDict["created"] as? String { createdAt = v }
    if let v = dict["baseNoteRevision"] as? String { serverRevision = v }
    if let v = previewDataDict["checkedCheckboxesCount"] as? String { checkedCheckboxesCount = v }
    isDirty = false
  }

  static func parse(dict: [String: Any], email: String) throws -> Note {
    let timestampsDict = (dict["timestamps"] as? [String: Any]) ?? [:]
    let previewDataDict = (dict["previewData"] as? [String: Any]) ?? [:]

    var mutableDict = dict
    mutableDict["email"] = email
    mutableDict["trashedAt"] = timestampsDict["trashed"] as? String ?? ""
    mutableDict["deletedAt"] = timestampsDict["deleted"] as? String ?? ""
    mutableDict["checkedCheckboxesCount"] =
      previewDataDict["checkedCheckboxesCount"] as? String ?? ""
    mutableDict["serverRevision"] = dict["baseNoteRevision"] as? String ?? ""
    mutableDict["createdAt"] = timestampsDict["created"] as? String ?? ""

    return decode(dict: mutableDict)
  }

  func toApiDict(parentServerId: String? = nil) -> [String: Any] {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let now = formatter.string(from: Date())
    let created = createdAt.isEmpty ? now : createdAt

    let resolvedSortValue =
      sortValue.isEmpty
      ? String(Int64.random(in: 1_000_000_000...9_999_999_999))
      : sortValue

    var timestamps: [String: Any] = [
      "kind": "notes#timestamps",
      "created": created,
      "updated": now,
      "userEdited": now,
    ]
    if !trashedAt.isEmpty { timestamps["trashed"] = trashedAt }
    if !deletedAt.isEmpty { timestamps["deleted"] = deletedAt }

    var dict: [String: Any] = [
      "id": id,
      "kind": "notes#node",
      "type": type,
      "parentId": parentId,
      "sortValue": resolvedSortValue,
      "text": text,
      "isArchived": isArchived,
      "timestamps": timestamps,
      "nodeSettings": [
        "newListItemPlacement": "BOTTOM",
        "graveyardState": "COLLAPSED",
        "checkedListItemsPolicy": "GRAVEYARD",
      ],
      "annotationsGroup": ["kind": "notes#annotationsGroup"],
    ]

    if !serverId.isEmpty { dict["serverId"] = serverId }
    if !serverRevision.isEmpty { dict["baseNoteRevision"] = serverRevision }

    if parentId == "root" {
      dict["title"] = title
      dict["color"] = color.isEmpty ? "DEFAULT" : color
      dict["isPinned"] = false
      dict["collaborators"] = [] as [[String: Any]]
    } else {
      dict["checked"] = checked
      if let ps = parentServerId { dict["parentServerId"] = ps }
    }

    return dict
  }

  func encode() -> [String: Any] {
    return [
      "email": email,
      "id": id,
      "serverId": serverId,
      "kind": kind,
      "parentId": parentId,
      "type": type,
      "trashedAt": trashedAt,
      "deletedAt": deletedAt,
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
