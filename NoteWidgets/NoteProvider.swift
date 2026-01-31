import SwiftData
import SwiftUI
import WidgetKit

struct NoteProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NoteEntry {
    return NoteEntry(date: Date(), configuration: NoteAppIntent(), notes: [])
  }

  func snapshot(for configuration: NoteAppIntent, in context: Context) async -> NoteEntry {
    return NoteEntry(date: Date(), configuration: configuration, notes: createSampleNotes())
  }

  func timeline(for configuration: NoteAppIntent, in context: Context) async -> Timeline<
    NoteEntry
  > {
    let entry = NoteEntry(date: Date(), configuration: configuration, notes: createSampleNotes())
    return Timeline(entries: [entry], policy: .never)
  }

  private func createSampleNotes() -> [Note] {
    return [
      Note(title: "Title1", text: "Text1"),
      Note(title: "Title2", text: "Text2"),
      Note(title: "Title3", text: "Text3"),
    ]
  }
}
