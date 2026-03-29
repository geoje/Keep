import SwiftUI

struct NoteDetailView: View {
  @Bindable var note: Note
  let allNotes: [Note]
  var namespace: Namespace.ID
  let onClose: () -> Void

  @Environment(\.colorScheme) var colorScheme

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

      // Content
      if note.type == "LIST" {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(children) { child in
            ChecklistItemEditRow(item: child)
          }
        }
      } else {
        TextField("Note", text: $note.text, axis: .vertical)
          .font(.body)
          .textFieldStyle(.plain)
          .frame(minHeight: 40, alignment: .topLeading)
      }

      Divider()
        .padding(.top, 4)

      // Bottom toolbar
      HStack(spacing: 0) {
        Button {
        } label: {
          Image(systemName: "paintpalette")
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
        Button {
        } label: {
          Image(systemName: "checklist")
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
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(10)
    .background(NoteService.shared.noteColor(for: note.color, colorScheme: colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .matchedGeometryEffect(id: note.id, in: namespace)
  }
}

struct ChecklistItemEditRow: View {
  @Bindable var item: Note

  var body: some View {
    HStack(spacing: 6) {
      Button {
        item.checked.toggle()
      } label: {
        Image(systemName: item.checked ? "checkmark.square.fill" : "square")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)

      TextField("Item", text: $item.text)
        .font(.body)
        .textFieldStyle(.plain)
        .foregroundStyle(item.checked ? .secondary : .primary)
        .strikethrough(item.checked)
    }
  }
}
