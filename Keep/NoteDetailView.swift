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

      // Content
      if !note.checkedCheckboxesCount.isEmpty && note.type == "LIST" {
        FlatChecklistEditView(note: note)
      } else if !note.checkedCheckboxesCount.isEmpty {
        TextField("Note", text: $note.indexableText, axis: .vertical)
          .font(.body)
          .textFieldStyle(.plain)
          .frame(minHeight: 40, alignment: .topLeading)
      } else if note.type == "LIST" {
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
        .overlay(alignment: .leading) {
          if item.checked {
            Text(item.text)
              .font(.body)
              .foregroundStyle(.clear)
              .strikethrough(true, color: .secondary)
              .allowsHitTesting(false)
          }
        }
    }
  }
}

struct FlatChecklistEditView: View {
  @Bindable var note: Note

  private var checkedCount: Int { max(0, Int(note.checkedCheckboxesCount) ?? 0) }

  private var items: [String] {
    note.indexableText.components(separatedBy: "\n")
  }

  private func isChecked(at index: Int) -> Bool {
    index >= items.count - checkedCount
  }

  private func toggleItem(at index: Int) {
    var all = items
    let currently = isChecked(at: index)
    let item = all.remove(at: index)
    if currently {
      all.insert(item, at: max(0, all.count - checkedCount + 1))
      note.checkedCheckboxesCount = String(max(0, checkedCount - 1))
    } else {
      all.append(item)
      note.checkedCheckboxesCount = String(checkedCount + 1)
    }
    note.indexableText = all.joined(separator: "\n")
  }

  private func updateText(_ newText: String, at index: Int) {
    var all = items
    all[index] = newText
    note.indexableText = all.joined(separator: "\n")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(items.indices, id: \.self) { index in
        let checked = isChecked(at: index)
        HStack(spacing: 6) {
          Button {
            toggleItem(at: index)
          } label: {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
              .foregroundStyle(.secondary)
              .opacity(checked ? 1 : 0.4)
          }
          .buttonStyle(.plain)

          let binding = Binding<String>(
            get: { items[index] },
            set: { updateText($0, at: index) }
          )
          TextField("Item", text: binding)
            .font(.body)
            .textFieldStyle(.plain)
            .foregroundStyle(checked ? .secondary : .primary)
            .overlay(alignment: .leading) {
              if checked {
                Text(items[index])
                  .font(.body)
                  .foregroundStyle(.clear)
                  .strikethrough(true, color: .secondary)
                  .allowsHitTesting(false)
              }
            }
        }
      }
    }
  }
}
