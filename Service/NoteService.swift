import Foundation

class NoteService {
  func getRootNotes(notes: [Note], email: String) -> [Note] {
    notes.filter {
      $0.email == email && $0.parentId == "root" && !$0.isArchived
        && $0.trashed.first != Character("2")
    }.sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
  }
}
