import SwiftUI

private struct IdentifiedString: Identifiable, Equatable {
  let id: UUID
  var text: String

  init(text: String) {
    self.id = UUID()
    self.text = text
  }
}

struct ChecklistProfileEditView: View {
  @Bindable var note: Note
  @State private var showChecked = true
  @State private var uncheckedEditing: [IdentifiedString] = []

  @State private var draggedItem: IdentifiedString?
  @State private var dragTransY: CGFloat = 0
  @State private var dragOriginalIdx: Int = 0
  @State private var localOrder: [IdentifiedString] = []

  @State private var rowHeight: CGFloat?

  private var checkedCount: Int { max(0, Int(note.checkedCheckboxesCount) ?? 0) }

  private var items: [String] {
    note.indexableText.components(separatedBy: "\n")
  }

  private var checkedIndices: [Int] {
    let total = items.count
    let start = max(0, total - checkedCount)
    return Array(start..<total)
  }

  private var displayUnchecked: [IdentifiedString] {
    draggedItem != nil ? localOrder : uncheckedEditing
  }

  private func fractionalDragOffset(for item: IdentifiedString) -> CGFloat {
    guard let rowHeight, let currentIdx = localOrder.firstIndex(of: item) else { return 0 }
    let idealY = CGFloat(dragOriginalIdx) * rowHeight + dragTransY
    let currentY = CGFloat(currentIdx) * rowHeight
    return idealY - currentY
  }

  private func loadUncheckedEditing() {
    let total = items.count
    let uncheckedCount = max(0, total - checkedCount)
    uncheckedEditing = (0..<uncheckedCount).map { IdentifiedString(text: items[$0]) }
  }

  private func syncIndexableText() {
    let checkedTexts = checkedIndices.map { items[$0] }
    note.indexableText = (uncheckedEditing.map(\.text) + checkedTexts).joined(separator: "\n")
    note.isDirty = true
  }

  private func addItem() {
    uncheckedEditing.append(IdentifiedString(text: ""))
    syncIndexableText()
  }

  private func toggleUnchecked(id: UUID) {
    guard let rawIdx = uncheckedEditing.firstIndex(where: { $0.id == id }) else { return }
    let text = uncheckedEditing[rawIdx].text
    uncheckedEditing.remove(at: rawIdx)
    var all = uncheckedEditing.map(\.text) + checkedIndices.map { items[$0] }
    all.append(text)
    note.indexableText = all.joined(separator: "\n")
    note.checkedCheckboxesCount = String(checkedCount + 1)
    note.isDirty = true
  }

  private func toggleChecked(rawIdx: Int) {
    guard rawIdx < items.count else { return }
    let text = items[rawIdx]
    var all = items
    all.remove(at: rawIdx)
    let insertAt = max(0, all.count - (checkedCount - 1))
    all.insert(text, at: insertAt)
    note.indexableText = all.joined(separator: "\n")
    note.checkedCheckboxesCount = String(max(0, checkedCount - 1))
    note.isDirty = true
    uncheckedEditing.append(IdentifiedString(text: text))
  }

  private func deleteUnchecked(id: UUID) {
    guard let rawIdx = uncheckedEditing.firstIndex(where: { $0.id == id }) else { return }
    uncheckedEditing.remove(at: rawIdx)
    let all = uncheckedEditing.map(\.text) + checkedIndices.map { items[$0] }
    note.indexableText = all.joined(separator: "\n")
    note.isDirty = true
  }

  private func deleteChecked(rawIdx: Int) {
    guard rawIdx < items.count else { return }
    var all = items
    all.remove(at: rawIdx)
    note.indexableText = all.joined(separator: "\n")
    note.checkedCheckboxesCount = String(max(0, checkedCount - 1))
    note.isDirty = true
  }

  private func startDrag(_ item: IdentifiedString) {
    guard draggedItem == nil else { return }
    draggedItem = item
    dragOriginalIdx = uncheckedEditing.firstIndex(of: item) ?? 0
    localOrder = uncheckedEditing
    dragTransY = 0
  }

  private func updateDrag(translationY: CGFloat) {
    dragTransY = translationY
    guard let rowHeight, let item = draggedItem else { return }
    let rawTarget = CGFloat(dragOriginalIdx) + translationY / rowHeight
    let targetIdx = max(0, min(localOrder.count - 1, Int(rawTarget.rounded())))
    let currentIdx = localOrder.firstIndex(of: item) ?? dragOriginalIdx
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
    uncheckedEditing = localOrder
    syncIndexableText()
    withAnimation(.easeInOut(duration: 0.2)) {
      draggedItem = nil
      dragTransY = 0
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(displayUnchecked) { idStr in
        let isDragging = idStr == draggedItem
        let textBinding = Binding<String>(
          get: { uncheckedEditing.first(where: { $0.id == idStr.id })?.text ?? "" },
          set: { newText in
            if let idx = uncheckedEditing.firstIndex(where: { $0.id == idStr.id }) {
              uncheckedEditing[idx].text = newText
              syncIndexableText()
            }
          }
        )
        ChecklistProfileItemRow(
          isChecked: false,
          text: textBinding,
          onToggle: { toggleUnchecked(id: idStr.id) },
          onDelete: { deleteUnchecked(id: idStr.id) },
          onDragStart: { startDrag(idStr) },
          onDragChange: { updateDrag(translationY: $0) },
          onDragEnd: { endDrag() },
          isDragActive: isDragging
        )
        .offset(y: isDragging ? fractionalDragOffset(for: idStr) : 0)
        .zIndex(isDragging ? 1 : 0)
        .background(
          GeometryReader { geo in
            Color.clear.onAppear { rowHeight = geo.size.height + 4 }
          }
        )
      }

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
              get: { index < items.count ? items[index] : "" },
              set: { newText in
                guard index < items.count else { return }
                var all = items
                all[index] = newText
                note.indexableText = all.joined(separator: "\n")
                note.isDirty = true
              }
            )
            ChecklistProfileItemRow(
              isChecked: true,
              text: binding,
              onToggle: { toggleChecked(rawIdx: index) },
              onDelete: { deleteChecked(rawIdx: index) }
            )
          }
        }
      }
    }
    .onAppear { loadUncheckedEditing() }
  }
}

private struct ChecklistProfileItemRow: View {
  let isChecked: Bool
  @Binding var text: String
  let onToggle: () -> Void
  let onDelete: () -> Void
  var onDragStart: (() -> Void)? = nil
  var onDragChange: ((CGFloat) -> Void)? = nil
  var onDragEnd: (() -> Void)? = nil
  var isDragActive: Bool = false

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

      if isHovered || isFocused || isDragActive {
        if !isChecked {
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
