import SwiftData
import SwiftUI

struct NoteDetailView: View {
  @Bindable var note: Note
  let allNotes: [Note]
  var namespace: Namespace.ID
  let onClose: () -> Void

  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @State private var showColorPicker = false

  private let colorOptions: [String] = [
    "", "RED", "ORANGE", "YELLOW", "GREEN", "TEAL",
    "CERULEAN", "BLUE", "PURPLE", "PINK", "BROWN", "GRAY",
  ]

  private var children: [Note] {
    allNotes.filter { $0.parentId == note.id && $0.deletedAt.isEmpty }
      .sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
  }

  private func deleteChild(_ child: Note) {
    if child.serverId.isEmpty {
      modelContext.delete(child)
    } else {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      child.deletedAt = formatter.string(from: Date())
      child.isDirty = true
    }
  }

  private func makeId() -> String {
    let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    return "cbx." + String((0..<12).map { _ in chars.randomElement()! })
  }

  private func playListToNote() {
    let text = children.map { $0.text }.joined(separator: "\n")
    for child in children { deleteChild(child) }
    let item = Note(
      email: note.email, id: makeId(), parentId: note.id, type: "LIST_ITEM",
      title: "", text: text, sortValue: "1000000000")
    item.isDirty = true
    modelContext.insert(item)
    note.type = "NOTE"
    note.isDirty = true
  }

  private func playNoteToList() {
    let source = children.first?.text ?? note.text
    let lines = source.components(separatedBy: "\n").filter { !$0.isEmpty }
    for child in children { deleteChild(child) }
    note.text = ""
    for (i, line) in lines.enumerated() {
      let item = Note(
        email: note.email, id: makeId(), parentId: note.id, type: "LIST_ITEM",
        title: "", text: line, sortValue: String(1_000_000_000 - i * 10_000))
      item.isDirty = true
      modelContext.insert(item)
    }
    note.type = "LIST"
    note.isDirty = true
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Title
      TextField("Title", text: $note.title)
        .font(.headline)
        .textFieldStyle(.plain)
        .onChange(of: note.title) { note.isDirty = true }

      // Content
      if !note.checkedCheckboxesCount.isEmpty && note.type == "LIST" {
        ChecklistProfileEditView(note: note)
      } else if !note.checkedCheckboxesCount.isEmpty {
        TextEditor(text: $note.indexableText)
          .font(.body)
          .scrollDisabled(true)
          .scrollContentBackground(.hidden)
          .background(.clear)
          .padding(.horizontal, -5)
          .frame(minHeight: 40, alignment: .topLeading)
          .onChange(of: note.indexableText) { note.isDirty = true }
      } else if note.type == "LIST" {
        ChecklistPlayEditView(note: note, children: children)
      } else if let textChild = children.first {
        TextEditor(text: Bindable(textChild).text)
          .font(.body)
          .scrollDisabled(true)
          .scrollContentBackground(.hidden)
          .background(.clear)
          .padding(.horizontal, -5)
          .frame(minHeight: 40, alignment: .topLeading)
          .onChange(of: textChild.text) {
            textChild.isDirty = true
            note.isDirty = true
          }
      } else {
        TextEditor(text: $note.text)
          .font(.body)
          .scrollDisabled(true)
          .scrollContentBackground(.hidden)
          .background(.clear)
          .padding(.horizontal, -5)
          .frame(minHeight: 40, alignment: .topLeading)
          .onChange(of: note.text) { note.isDirty = true }
      }

      Divider()
        .padding(.top, 4)

      // Bottom toolbar
      HStack(spacing: 0) {
        Button {
          if note.checkedCheckboxesCount.isEmpty {
            if note.type == "LIST" {
              playListToNote()
            } else {
              playNoteToList()
            }
          } else {
            if note.type == "LIST" {
              note.type = "NOTE"
            } else {
              note.type = "LIST"
              if note.checkedCheckboxesCount.isEmpty {
                note.checkedCheckboxesCount = "0"
              }
            }
            note.isDirty = true
          }
        } label: {
          Image(systemName: note.type == "LIST" ? "checklist" : "character.text.justify")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        Button {
          withAnimation(.spring(duration: 0.2)) {
            showColorPicker.toggle()
          }
        } label: {
          Image(systemName: "paintpalette")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        Button {
          let formatter = ISO8601DateFormatter()
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          note.trashedAt = formatter.string(from: Date())
          note.isDirty = true
          onClose()
        } label: {
          Image(systemName: "trash")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        Spacer()
        Button(action: onClose) {
          Image(systemName: "xmark")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        .keyboardShortcut(.escape, modifiers: [])
      }
      .buttonStyle(.plain)
      .foregroundStyle(.secondary)
      .font(.body)

      if showColorPicker {
        Divider()
        FlowLayout(spacing: 10) {
          ForEach(colorOptions, id: \.self) { colorKey in
            let bgColor = NoteService.shared.noteColor(for: colorKey, colorScheme: colorScheme)
            Button {
              note.color = colorKey
              note.isDirty = true
            } label: {
              Circle()
                .fill(bgColor)
                .frame(width: 24, height: 24)
                .overlay(
                  Circle()
                    .strokeBorder(
                      note.color.uppercased() == colorKey.uppercased()
                        ? Color.primary : Color.secondary.opacity(0.3),
                      lineWidth: note.color.uppercased() == colorKey.uppercased() ? 2 : 1
                    )
                )
                .overlay(
                  Group {
                    if colorKey.isEmpty {
                      Image(systemName: "drop.degreesign.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }
                  }
                )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(10)
    .background(NoteService.shared.noteColor(for: note.color, colorScheme: colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
          Color.primary.opacity(
            NoteService.shared.noteColor(for: note.color, colorScheme: colorScheme) == .clear
              ? 0.2 : 0), lineWidth: 1)
    )
    .matchedGeometryEffect(id: note.id, in: namespace)
  }
}
