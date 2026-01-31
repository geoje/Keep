import WidgetKit
import SwiftData

struct NoteEntry: TimelineEntry {
  let date: Date
  let configuration: NoteAppIntent
  let notes: [Note]
}
