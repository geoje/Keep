import WidgetKit

struct NoteEntry: TimelineEntry {
  let date: Date
  let configuration: NoteAppIntent
  let note: NoteEntity?
}
