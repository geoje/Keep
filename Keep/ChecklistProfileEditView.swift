import SwiftUI

struct ChecklistProfileEditView: View {
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
        ChecklistProfileItemRow(
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
            ChecklistProfileItemRow(
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

struct ChecklistProfileItemRow: View {
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
