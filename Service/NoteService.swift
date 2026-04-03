import Foundation
import SwiftUI

class NoteService {
  static let shared = NoteService()

  func getRootNotes(notes: [Note], email: String) -> [Note] {
    notes.filter {
      $0.email == email && $0.parentId == "root" && !$0.isArchived
        && $0.trashedAt.first != Character("2")
    }.sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
  }

  func noteColor(for color: String, colorScheme: ColorScheme) -> Color {
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
    default: return .clear
    }
  }
}

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
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
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
