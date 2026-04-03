import AppKit
import FirebaseAnalytics
import FirebaseCore
import Foundation
import SwiftData
import SwiftUI

extension Notification.Name {
  static let deselectNote = Notification.Name("deselectNote")
}

private class PopoverContentController: NSHostingController<ContentView> {
  override func cancelOperation(_ sender: Any?) {
    if NoteSelectionState.shared.noteIsSelected {
      NotificationCenter.default.post(name: .deselectNote, object: nil)
    } else {
      super.cancelOperation(sender)
    }
  }
}

final class NoteSelectionState {
  static let shared = NoteSelectionState()
  var noteIsSelected = false
}

class AppDelegate: NSObject, NSApplicationDelegate {
  var statusItem: NSStatusItem!
  var popover: NSPopover!

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    HttpServer(modelContainer: ModelContainer.shared).start()
    FirebaseApp.configure()
    Analytics.setAnalyticsCollectionEnabled(true)
    setupStatusItem()
  }

  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem.button {
      if let image = NSImage(named: "MenuBarIcon") {
        button.image = image
      } else {
        button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: nil)
      }
      button.action = #selector(togglePopover)
      button.target = self
    }

    popover = NSPopover()
    popover.contentSize = NSSize(width: 360, height: 480)
    popover.behavior = .transient
    popover.animates = true
    popover.contentViewController = PopoverContentController(rootView: ContentView())
  }

  @objc func togglePopover() {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(nil)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }
}

@main
struct KeepApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    Settings { EmptyView() }
  }
}
