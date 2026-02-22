import Foundation
import Network
import SwiftData

class HttpServer {
  private let port: NWEndpoint.Port = 14339
  private var listener: NWListener?
  private let modelContext: ModelContext

  init(modelContainer: ModelContainer) {
    self.modelContext = modelContainer.mainContext
  }

  func start() {
    do {
      listener = try NWListener(using: .tcp, on: port)
    } catch {
      print("Failed to start listener: \(error)")
      return
    }

    listener?.newConnectionHandler = { connection in
      connection.start(queue: .main)
      connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
        let response =
          "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n[]"
        connection.send(
          content: response.data(using: .utf8),
          completion: .contentProcessed { _ in
            connection.cancel()
          })
      }
    }

    listener?.start(queue: .main)
  }
}
