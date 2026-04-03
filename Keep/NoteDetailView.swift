import SwiftUI

struct NoteDetailView: View {
  @Bindable var note: Note
  let allNotes: [Note]
  var namespace: Namespace.ID
  let onClose: () -> Void

  @Environment(\.colorScheme) var colorScheme
  @State private var showColorPicker = false

  private let colorOptions: [String] = [
    "", "RED", "ORANGE", "YELLOW", "GREEN", "TEAL",
    "CERULEAN", "BLUE", "PURPLE", "PINK", "BROWN", "GRAY",
  ]

  private var children: [Note] {
    allNotes.filter { $0.parentId == note.id }
      .sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
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
          withAnimation(.spring(duration: 0.2)) {
            showColorPicker.toggle()
          }
        } label: {
          Image(systemName: "paintpalette")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        Button {
        } label: {
          Image(systemName: note.type == "LIST" ? "checklist" : "character.text.justify")
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
