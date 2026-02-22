import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    return NoteEntry(
      date: Date(), configuration: NoteConfigurationIntent(),
      entity: NoteEntity.sampleEntity)
  }

  func snapshot(for configuration: NoteConfigurationIntent, in context: Context) async -> NoteEntry
  {
    let entity: NoteEntity?
    if let selectedNote = configuration.selectedNote {
      entity = selectedNote
    } else {
      entity = await getDefaultEntity()
    }
    return NoteEntry(date: Date(), configuration: configuration, entity: entity)
  }

  func timeline(for configuration: NoteConfigurationIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    let entity: NoteEntity?
    if let selectedNote = configuration.selectedNote {
      let query = NoteQuery()
      let entities = try? await query.entities(for: [selectedNote.id])
      entity = entities?.first
    } else {
      entity = await getDefaultEntity()
    }

    let entry = NoteEntry(
      date: Date(), configuration: configuration,
      entity: entity)
    return Timeline(entries: [entry], policy: .never)
  }

  private func getDefaultEntity() async -> NoteEntity {
    let query = NoteQuery()
    let entities = try? await query.suggestedEntities()
    return entities?.items.first ?? NoteEntity.sampleEntity
  }
}
