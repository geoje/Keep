import SwiftData
import SwiftUI

@main
struct KeepApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        ContentView()
      }
    }
    .modelContainer(ModelContainer.shared)
    .windowResizability(.contentSize)
  }
}
