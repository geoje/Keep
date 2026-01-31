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
      Note(email: "boy@gmail.com", id: "1", title: "NoteTitle1", text: "NoteText1"),
      Note(email: "boy@gmail.com", id: "2", title: "NoteTitle2", text: "NoteText2"),
      Note(email: "girl@gmail.com", id: "3", title: "NoteTitle3", text: "NoteText3"),
      Note(email: "girl@gmail.com", id: "4", title: "NoteTitle4", text: "NoteText4"),
    ]
  }
}
