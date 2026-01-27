import Foundation
import SwiftData

struct Timestamps: Codable {
  var kind: String = ""
  var created: String = ""
  var updated: String = ""
  var trashed: String = ""
  var userEdited: String = ""
}

struct NodeSettings: Codable {
  var newListItemPlacement: String = ""
  var checkedListItemsPolicy: String = ""
  var graveyardState: String = ""
}

struct AnnotationsGroup: Codable {
  var kind: String = ""
  var annotations: [Annotation] = []
}

struct Annotation: Codable {
  var id: String = ""
  var deleted: String = ""
  var topicCategory: TopicCategory?
  var webLink: WebLink?
}

struct TopicCategory: Codable {
  var category: String = ""
}

struct WebLink: Codable {
  var kind: String = ""
  var url: String = ""
  var title: String = ""
  var description: String = ""
  var provenanceUrl: String = ""
}

struct Background: Codable {
  var name: String = ""
  var origin: String = ""
}

@Model
final class Note {
  var email: String
  var id: String
  var kind: String
  var serverId: String
  var parentId: String
  var parentServerId: String
  var type: String
  var timestamps: Timestamps
  var title: String
  var text: String
  var nodeSettings: NodeSettings
  var isArchived: Bool
  var isPinned: Bool
  var color: String
  var sortValue: String
  var annotationsGroup: AnnotationsGroup
  var lastModifierEmail: String
  var moved: String
  var background: Background
  var baseNoteRevision: String
  var xplatModel: Bool
  var representation: String
  var checked: Bool

  init(
    email: String,
    id: String,
    kind: String = "",
    serverId: String = "",
    parentId: String = "",
    parentServerId: String = "",
    type: String = "",
    timestamps: Timestamps = Timestamps(),
    title: String = "",
    text: String = "",
    nodeSettings: NodeSettings = NodeSettings(),
    isArchived: Bool = false,
    isPinned: Bool = false,
    color: String = "",
    sortValue: String = "",
    annotationsGroup: AnnotationsGroup = AnnotationsGroup(),
    lastModifierEmail: String = "",
    moved: String = "",
    background: Background = Background(),
    baseNoteRevision: String = "",
    xplatModel: Bool = false,
    representation: String = "",
    checked: Bool = false
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
