import SwiftData
import SwiftUI

struct ChecklistPlayEditView: View {
  let note: Note
  let children: [Note]
  @State private var showChecked = true
  @Environment(\.modelContext) private var modelContext

  @State private var draggedNote: Note?
  @State private var dragTransY: CGFloat = 0
  @State private var dragOriginalIdx: Int = 0
  @State private var localOrder: [Note] = []

  @State private var rowHeight: CGFloat?

  private var unchecked: [Note] {
    children.filter { !$0.checked && $0.deletedAt.isEmpty }.sorted {
      (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0)
    }
  }
  private var checked: [Note] { children.filter { $0.checked && $0.deletedAt.isEmpty } }
  private var displayUnchecked: [Note] { draggedNote != nil ? localOrder : unchecked }

  private func fractionalDragOffset(for note: Note) -> CGFloat {
    guard let rowHeight, let currentIdx = localOrder.firstIndex(of: note) else { return 0 }
    let idealY = CGFloat(dragOriginalIdx) * rowHeight + dragTransY
    let currentY = CGFloat(currentIdx) * rowHeight
    return idealY - currentY
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(displayUnchecked) { child in
        let isDragging = child == draggedNote
        ChecklistPlayItemEditRow(
          item: child,
          isDragActive: isDragging,
          onDragStart: { startDrag(child) },
          onDragChange: { updateDrag(translationY: $0) },
          onDragEnd: { endDrag() },
          onDelete: { deleteItem(child) }
        )
        .offset(y: isDragging ? fractionalDragOffset(for: child) : 0)
        .zIndex(isDragging ? 1 : 0)
        .background(
          GeometryReader { geo in
            Color.clear.onAppear {
              rowHeight = geo.size.height + 4
            }
          }
        )
      }

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

  private func startDrag(_ note: Note) {
    guard draggedNote == nil else { return }
    draggedNote = note
    dragOriginalIdx = unchecked.firstIndex(of: note) ?? 0
    localOrder = unchecked
    dragTransY = 0
  }

  private func updateDrag(translationY: CGFloat) {
    dragTransY = translationY
    guard let rowHeight, let note = draggedNote else { return }
    let rawTarget = CGFloat(dragOriginalIdx) + translationY / rowHeight
    let targetIdx = max(0, min(localOrder.count - 1, Int(rawTarget.rounded())))
    let currentIdx = localOrder.firstIndex(of: note) ?? dragOriginalIdx
    if targetIdx != currentIdx {
      withAnimation(.easeInOut(duration: 0.2)) {
        localOrder.move(
          fromOffsets: IndexSet(integer: currentIdx),
          toOffset: targetIdx > currentIdx ? targetIdx + 1 : targetIdx
        )
      }
    }
  }

  private func endDrag() {
    for (i, item) in localOrder.enumerated() {
      item.sortValue = String(1_000_000_000 - i * 10_000)
      item.isDirty = true
    }
    withAnimation(.easeInOut(duration: 0.2)) {
      draggedNote = nil
      dragTransY = 0
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
  var isDragActive: Bool = false
  var onDragStart: (() -> Void)? = nil
  var onDragChange: ((CGFloat) -> Void)? = nil
  var onDragEnd: (() -> Void)? = nil
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

      if isHovered || isFocused || isDragActive {
        if !item.checked {
          Image(systemName: "line.3.horizontal")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .gesture(
              DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                  onDragStart?()
                  onDragChange?(value.translation.height)
                }
                .onEnded { _ in
                  onDragEnd?()
                }
            )
        }

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
