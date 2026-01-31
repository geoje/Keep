import AppIntents
import WidgetKit

struct NoteAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Configuration" }
  static var description: IntentDescription { "This is an example widget." }

  @Parameter(title: "Favorite Emoji", default: "😃")
  var favoriteEmoji: String
}
