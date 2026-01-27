import Foundation
import SwiftData

struct Timestamps: Codable {
  var kind: String?
  var created: String?
  var updated: String?
  var trashed: String?
  var userEdited: String?
}

struct NodeSettings: Codable {
  var newListItemPlacement: String?
  var checkedListItemsPolicy: String?
  var graveyardState: String?
}

struct AnnotationsGroup: Codable {
  var kind: String?
  var annotations: [Annotation]?
}

struct Annotation: Codable {
  var id: String?
  var deleted: String?
  var topicCategory: TopicCategory?
  var webLink: WebLink?
}

struct TopicCategory: Codable {
  var category: String?
}

struct WebLink: Codable {
  var kind: String?
  var url: String?
  var title: String?
  var description: String?
  var provenanceUrl: String?
}

struct Background: Codable {
  var name: String?
  var origin: String?
}

@Model
final class Note {
  var email: String
  var id: String
  var kind: String?
  var serverId: String?
  var parentId: String?
  var parentServerId: String?
  var type: String?
  var timestamps: Timestamps?
  var title: String?
  var text: String?
  var nodeSettings: NodeSettings?
  var isArchived: Bool?
  var isPinned: Bool?
  var color: String?
  var sortValue: String?
  var annotationsGroup: AnnotationsGroup?
  var lastModifierEmail: String?
  var moved: String?
  var background: Background?
  var baseNoteRevision: String?
  var xplatModel: Bool?
  var representation: String?
  var checked: Bool?

  init(
    email: String,
    id: String,
    kind: String? = nil,
    serverId: String? = nil,
    parentId: String? = nil,
    parentServerId: String? = nil,
    type: String? = nil,
    timestamps: Timestamps? = nil,
    title: String? = nil,
    text: String? = nil,
    nodeSettings: NodeSettings? = nil,
    isArchived: Bool? = nil,
    isPinned: Bool? = nil,
    color: String? = nil,
    sortValue: String? = nil,
    annotationsGroup: AnnotationsGroup? = nil,
    lastModifierEmail: String? = nil,
    moved: String? = nil,
    background: Background? = nil,
    baseNoteRevision: String? = nil,
    xplatModel: Bool? = nil,
    representation: String? = nil,
    checked: Bool? = nil
  ) {
    self.email = email
    self.id = id
    self.kind = kind
    self.serverId = serverId
    self.parentId = parentId
    self.parentServerId = parentServerId
    self.type = type
    self.timestamps = timestamps
    self.title = title
    self.text = text
    self.nodeSettings = nodeSettings
    self.isArchived = isArchived
    self.isPinned = isPinned
    self.color = color
    self.sortValue = sortValue
    self.annotationsGroup = annotationsGroup
    self.lastModifierEmail = lastModifierEmail
    self.moved = moved
    self.background = background
    self.baseNoteRevision = baseNoteRevision
    self.xplatModel = xplatModel
    self.representation = representation
    self.checked = checked
  }
}
