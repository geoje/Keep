import WidgetKit

struct NoteEntry: TimelineEntry {
  let date: Date
  let configuration: NoteConfigurationIntent
  let entity: NoteEntity?
}
