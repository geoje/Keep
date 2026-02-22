import Foundation
import Network
import SwiftData

class HttpServer {
  private let port: NWEndpoint.Port = 14339
  private var listener: NWListener?
  private let modelContainer: ModelContainer
  private let modelContext: ModelContext

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
  }

  func start() {
    do {
      listener = try NWListener(using: .tcp, on: port)
    } catch {
      return
    }

    listener?.newConnectionHandler = { connection in
      connection.start(queue: .main)
      connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
        guard let data = data, let requestString = String(data: data, encoding: .utf8) else {
          connection.cancel()
          return
        }
        let requestLine = requestString.components(separatedBy: "\r\n").first ?? ""
        let parts = requestLine.components(separatedBy: " ")
        let method = parts.first ?? ""
        let path = parts.count > 1 ? parts[1] : ""
        let response = self.handleRequest(method: method, path: path, connection: connection)
        connection.send(
          content: response.data(using: .utf8),
          completion: .contentProcessed { _ in
            connection.cancel()
          })
      }
    }

    listener?.start(queue: .main)
  }

  func handleRequest(method: String, path: String, connection: NWConnection) -> String {
    switch (method, path) {
    case ("GET", "/notes"):
      let noteDicts = self.getAllNotes().map { $0.encode() }
      let jsonData = try? JSONSerialization.data(withJSONObject: noteDicts, options: [])
      let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
      return
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(jsonString.utf8.count)\r\n\r\n\(jsonString)"

    default:
      return "HTTP/1.1 404 Not Found\r\n\r\n"
    }
  }

  func getAllNotes() -> [Note] {
    do {
      return try modelContext.fetch(FetchDescriptor<Note>())
    } catch {
      return []
    }
  }
}
