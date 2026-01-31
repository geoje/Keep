import AppIntents
import WidgetKit

struct NoteAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "NoteAppIntent.title" }
  static var description: IntentDescription { "NoteAppIntent.description" }

  @Parameter(
    title: "NoteAppIntent.favoriteEmoji.@Parameter.title", default: "NoteAppIntent.favoriteEmoji")
  var favoriteEmoji: String
}
