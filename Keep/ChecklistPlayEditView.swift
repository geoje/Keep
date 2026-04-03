import SwiftData
import SwiftUI

struct ChecklistPlayEditView: View {
  let note: Note
  let children: [Note]
  @State private var showChecked = true
  @Environment(\.modelContext) private var modelContext

  private var unchecked: [Note] { children.filter { !$0.checked && $0.deletedAt.isEmpty } }
  private var checked: [Note] { children.filter { $0.checked && $0.deletedAt.isEmpty } }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Unchecked items
      ForEach(unchecked) { child in
        ChecklistPlayItemEditRow(item: child, onDelete: { deleteItem(child) })
      }

      // Add item button
      Button {
        addNewItem()
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
            ChecklistPlayItemEditRow(item: child, onDelete: { deleteItem(child) })
          }
        }
      }
    }
  }

  private func deleteItem(_ item: Note) {
    if item.serverId.isEmpty {
      modelContext.delete(item)
    } else {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      item.deletedAt = formatter.string(from: Date())
      item.isDirty = true
    }
  }

  private func addNewItem() {
    let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    let randomSuffix = String((0..<12).map { _ in chars.randomElement()! })
    let newId = "cbx.\(randomSuffix)"

    let currentMinSort = unchecked.compactMap { Int($0.sortValue) }.min() ?? 1_000_000_000
    let newSortValue = String(currentMinSort - 10_000)

    let newItem = Note(
      email: note.email,
      id: newId,
      parentId: note.id,
      type: "LIST_ITEM",
      sortValue: newSortValue
    )
    newItem.isDirty = true
    modelContext.insert(newItem)
  }
}

struct ChecklistPlayItemEditRow: View {
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
