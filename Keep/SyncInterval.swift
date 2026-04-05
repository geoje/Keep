import Foundation

enum SyncInterval: String, CaseIterable {
  case everyMinute
  case every5Minutes
  case every15Minutes
  case every30Minutes
  case everyHour
  case manually

  var title: String {
    switch self {
    case .everyMinute: return "Every minute"
    case .every5Minutes: return "Every 5 minutes"
    case .every15Minutes: return "Every 15 minutes"
    case .every30Minutes: return "Every 30 minutes"
    case .everyHour: return "Every hour"
    case .manually: return "Manually"
    }
  }

  var seconds: TimeInterval? {
    switch self {
    case .everyMinute: return 60
    case .every5Minutes: return 300
    case .every15Minutes: return 900
    case .every30Minutes: return 1800
    case .everyHour: return 3600
    case .manually: return nil
    }
  }

  static let userDefaultsKey = "syncInterval"
  static let defaultValue = SyncInterval.every15Minutes
}
