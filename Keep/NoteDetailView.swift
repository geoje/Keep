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
        FlatChecklistEditView(note: note)
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
        ChecklistEditView(children: children)
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

struct FlatChecklistEditView: View {
  @Bindable var note: Note
  @State private var showChecked = true

  private var checkedCount: Int { max(0, Int(note.checkedCheckboxesCount) ?? 0) }

  private var items: [String] {
    note.indexableText.components(separatedBy: "\n")
  }

  private var uncheckedIndices: [Int] {
    let total = items.count
    let start = max(0, total - checkedCount)
    return Array(0..<start)
  }

  private var checkedIndices: [Int] {
    let total = items.count
    let start = max(0, total - checkedCount)
    return Array(start..<total)
  }

  private func toggleItem(at index: Int) {
    let isChecked = checkedIndices.contains(index)
    let newCheckedCount = isChecked ? max(0, checkedCount - 1) : checkedCount + 1
    var all = items
    let item = all.remove(at: index)
    if isChecked {
      all.insert(item, at: max(0, all.count - checkedCount + 1))
    } else {
      all.append(item)
    }
    note.indexableText = all.joined(separator: "\n")
    note.checkedCheckboxesCount = String(newCheckedCount)
    note.isDirty = true
  }

  private func updateText(_ newText: String, at index: Int) {
    var all = items
    all[index] = newText
    note.indexableText = all.joined(separator: "\n")
    note.isDirty = true
  }

  private func addItem() {
    var all = items
    let insertAt = max(0, all.count - checkedCount)
    all.insert("", at: insertAt)
    note.indexableText = all.joined(separator: "\n")
    note.isDirty = true
  }

  private func deleteItem(at index: Int) {
    let isChecked = checkedIndices.contains(index)
    let newCheckedCount = isChecked ? max(0, checkedCount - 1) : checkedCount
    var all = items
    all.remove(at: index)
    note.indexableText = all.joined(separator: "\n")
    note.checkedCheckboxesCount = String(newCheckedCount)
    note.isDirty = true
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Unchecked items
      ForEach(uncheckedIndices, id: \.self) { index in
        let binding = Binding<String>(
          get: { items[index] },
          set: { updateText($0, at: index) }
        )
        FlatChecklistItemRow(
          isChecked: false,
          text: binding,
          onToggle: { toggleItem(at: index) },
          onDelete: { deleteItem(at: index) }
        )
      }

      // Add item button
      Button {
        addItem()
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "plus")
            .foregroundStyle(.secondary)
            .opacity(0.6)
          Text("List item")
            .font(.body)
            .foregroundStyle(.tertiary)
        }
      }
      .buttonStyle(.plain)

      if checkedCount > 0 {
        Divider()
          .padding(.vertical, 4)

        // Checked section toggle
        Button {
          withAnimation(.easeInOut(duration: 0.2)) { showChecked.toggle() }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "chevron.up")
              .rotationEffect(.degrees(showChecked ? 180 : 0))
              .foregroundStyle(.secondary)
              .opacity(0.6)
            Text("\(checkedCount) Completed item\(checkedCount == 1 ? "" : "s")")
              .font(.body)
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)

        if showChecked {
          ForEach(checkedIndices, id: \.self) { index in
            let binding = Binding<String>(
              get: { items[index] },
              set: { updateText($0, at: index) }
            )
            FlatChecklistItemRow(
              isChecked: true,
              text: binding,
              onToggle: { toggleItem(at: index) },
              onDelete: { deleteItem(at: index) }
            )
          }
        }
      }
    }
  }
}

struct ChecklistEditView: View {
  let children: [Note]
  @State private var showChecked = true

  private var unchecked: [Note] { children.filter { !$0.checked } }
  private var checked: [Note] { children.filter { $0.checked } }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Unchecked items
      ForEach(unchecked) { child in
        ChecklistItemEditRow(item: child)
      }

      // Add item button
      Button {
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "plus")
            .foregroundStyle(.secondary)
            .opacity(0.6)
          Text("List item")
            .font(.body)
            .foregroundStyle(.tertiary)
        }
      }
      .buttonStyle(.plain)

      if !checked.isEmpty {
        Divider()
          .padding(.vertical, 4)

        // Checked section toggle
        Button {
          withAnimation(.easeInOut(duration: 0.2)) { showChecked.toggle() }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "chevron.up")
              .rotationEffect(.degrees(showChecked ? 180 : 0))
              .foregroundStyle(.secondary)
              .opacity(0.6)
            Text("\(checked.count) Completed item\(checked.count == 1 ? "" : "s")")
              .font(.body)
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)

        if showChecked {
          ForEach(checked) { child in
            ChecklistItemEditRow(item: child)
          }
        }
      }
    }
  }
}

struct ChecklistItemEditRow: View {
  @Bindable var item: Note
  var onDelete: (() -> Void)? = nil

  @State private var isHovered = false
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 6) {
      Button {
        item.checked.toggle()
        item.isDirty = true
      } label: {
        Image(systemName: item.checked ? "checkmark.square.fill" : "square")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .onHover { inside in
        NSCursor.pointingHand.set()
        if !inside { NSCursor.arrow.set() }
      }

      TextField("", text: $item.text)
        .font(.body)
        .textFieldStyle(.plain)
        .foregroundStyle(item.checked ? .secondary : .primary)
        .focused($isFocused)
        .onChange(of: item.text) { item.isDirty = true }
        .overlay(alignment: .leading) {
          if item.checked {
            Text(item.text)
              .font(.body)
              .foregroundStyle(.clear)
              .strikethrough(true, color: .secondary)
              .allowsHitTesting(false)
          }
        }

      if isHovered || isFocused {
        Button {
          onDelete?()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .onHover { inside in isHovered = inside }
  }
}

struct FlatChecklistItemRow: View {
  let isChecked: Bool
  @Binding var text: String
  let onToggle: () -> Void
  let onDelete: () -> Void

  @State private var isHovered = false
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 6) {
      Button {
        onToggle()
      } label: {
        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
          .foregroundStyle(.secondary)
          .opacity(isChecked ? 1 : 0.4)
      }
      .buttonStyle(.plain)
      .onHover { inside in
        NSCursor.pointingHand.set()
        if !inside { NSCursor.arrow.set() }
      }

      TextField("", text: $text)
        .font(.body)
        .textFieldStyle(.plain)
        .foregroundStyle(isChecked ? .secondary : .primary)
        .focused($isFocused)
        .overlay(alignment: .leading) {
          if isChecked {
            Text(text)
              .font(.body)
              .foregroundStyle(.clear)
              .strikethrough(true, color: .secondary)
              .allowsHitTesting(false)
          }
        }

      if isHovered || isFocused {
        Button {
          onDelete()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .onHover { inside in isHovered = inside }
  }
}
