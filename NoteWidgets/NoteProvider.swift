import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    NoteEntry(date: Date(), configuration: NoteAppIntent())
  }

  func snapshot(for configuration: NoteAppIntent, in context: Context) async -> NoteEntry {
    NoteEntry(date: Date(), configuration: configuration)
  }

  func timeline(for configuration: NoteAppIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    var entries: [NoteEntry] = []

    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = NoteEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }

    return Timeline(entries: entries, policy: .atEnd)
  }
}
