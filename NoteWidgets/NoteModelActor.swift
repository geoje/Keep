import AppIntents
import SwiftData
import WidgetKit

actor NoteModelActor: ModelActor {
  let modelContainer: ModelContainer
  let modelContext: ModelContext
  let modelExecutor: any ModelExecutor
  let googleApiService: GoogleApiService
  let chromeDriverService: ChromeDriverService
  let chromeProfileService: ChromeProfileService
  let noteService: NoteService

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    self.googleApiService = GoogleApiService()
    self.chromeDriverService = ChromeDriverService()
    self.chromeProfileService = ChromeProfileService(chromeDriverService: self.chromeDriverService)
    self.noteService = NoteService()
  }

  func fetchNotes() throws -> [NoteEntity] {
    let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.email)])
    let noteDescriptor = FetchDescriptor<Note>()
    let accounts = try modelContext.fetch(accountDescriptor)
    let allNotes = try modelContext.fetch(noteDescriptor)

    var entities: [NoteEntity] = []
    for account in accounts {
      let rootNotes = noteService.getRootNotes(notes: allNotes, email: account.email)
      entities.append(NoteEntity(id: account.email, email: ""))
      entities.append(
        contentsOf: rootNotes.map {
          let uncheckedItems = noteService.parseUncheckedItems(
            notes: allNotes, rootNoteId: $0.id)
          let checkedItems = noteService.parseCheckedItems(notes: allNotes, rootNoteId: $0.id)

          if $0.type == "LIST" {
            return NoteEntity(
              id: $0.id, email: $0.email, color: $0.color, title: $0.title,
              uncheckedItems: uncheckedItems,
              checkedItems: checkedItems, type: $0.type, serverId: $0.serverId)
          } else {
            return NoteEntity(
              id: $0.id, email: $0.email, color: $0.color, title: $0.title,
              text: uncheckedItems.joined(separator: "\n"), type: $0.type, serverId: $0.serverId)
          }
        })
    }

    return entities
  }

  func syncNotesForAccount(email: String) async throws {
    let accountDescriptor = FetchDescriptor<Account>(
      predicate: #Predicate { $0.email == email }
    )
    if let account = try modelContext.fetch(accountDescriptor).first {
      if !account.masterToken.isEmpty {
        try await googleApiService.syncNotes(for: account, modelContext: modelContext)
      } else if !account.profileName.isEmpty {
        try await chromeProfileService.syncNotes(for: account, modelContext: modelContext)
      }
    }
  }
}
