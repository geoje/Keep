import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(date: Date(), configuration: configuration)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    var entries: [SimpleEntry] = []

    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, configuration: configuration)
      entries.append(entry)
    }

    return Timeline(entries: entries, policy: .atEnd)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
}

struct NoteWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      Text("Time:")
      Text(entry.date, style: .time)

      Text("Favorite Emoji:")
      Text(entry.configuration.favoriteEmoji)
    }
  }
}

struct NoteWidget: Widget {
  let kind: String = "NoteWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      NoteWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}
