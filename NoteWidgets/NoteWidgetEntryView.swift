import SwiftUI
import WidgetKit

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 255, 255, 255)  // Default to white
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

struct NoteWidgetEntryView: View {
  @Environment(\.colorScheme) var colorScheme
  var entry: NoteEntry

  private func backgroundColor(for color: String) -> Color {
    let upper = color.uppercased()
    let isDark = colorScheme == .dark
    switch upper {
    case "RED": return isDark ? Color(hex: "#77172e") : Color(hex: "#faafa8")
    case "ORANGE": return isDark ? Color(hex: "#692b18") : Color(hex: "#f39f76")
    case "YELLOW": return isDark ? Color(hex: "#7c4b03") : Color(hex: "#fff8b8")
    case "GREEN": return isDark ? Color(hex: "#264d3b") : Color(hex: "#e2f6d3")
    case "TEAL": return isDark ? Color(hex: "#0d625d") : Color(hex: "#b4ddd2")
    case "CERULEAN": return isDark ? Color(hex: "#266377") : Color(hex: "#d4e4ed")
    case "BLUE": return isDark ? Color(hex: "#284254") : Color(hex: "#aeccdc")
    case "PURPLE": return isDark ? Color(hex: "#482e5b") : Color(hex: "#d3bfdb")
    case "PINK": return isDark ? Color(hex: "#6b394f") : Color(hex: "#f6e2dd")
    case "BROWN": return isDark ? Color(hex: "#4b443a") : Color(hex: "#e9e3d4")
    case "GRAY": return isDark ? Color(hex: "#232427") : Color(hex: "#efeff1")
    default: return isDark ? Color(hex: "#202124") : Color(hex: "#ffffff")
    }
  }

  private func noteContentView(for note: NoteEntity) -> some View {
    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 4) {
        if !note.title.isEmpty {
          Text(note.title)
            .font(.headline)
        }
        if note.uncheckedItems.isEmpty && note.checkedItems.isEmpty {
          Text(note.text)
            .font(.body)
        } else {
          if !note.uncheckedItems.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              ForEach(note.uncheckedItems.indices, id: \.self) { index in
                let item = note.uncheckedItems[index]
                HStack(spacing: 4) {
                  Image(systemName: "square")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(0.4)
                  Text(item)
                    .font(.body)
                }
              }
            }
          }
          if !note.checkedItems.isEmpty {
            Text(
              "+ \(note.checkedItems.count) checked item\(note.checkedItems.count > 1 ? "s" : "")"
            )
            .font(.body)
            .foregroundColor(.secondary)
          }
        }
      }
      .foregroundColor(.primary)
      .frame(maxWidth: .infinity, maxHeight: geo.size.height, alignment: .topLeading)
    }
  }

  var body: some View {
    ZStack {
      if let note = entry.note {
        noteContentView(for: note)
          .widgetURL(URL(string: "https://keep.google.com/u/0/#\(note.type)/\(note.serverId)"))
      } else {
        Text("No selected note")
          .font(.body)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .widgetURL(URL(string: "https://keep.google.com/u/0/"))
      }
    }
    .containerBackground(for: .widget) { backgroundColor(for: entry.note?.color ?? "") }
  }
}
