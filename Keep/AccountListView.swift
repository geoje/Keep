import SwiftData
import SwiftUI

struct AccountListView: View {
  @Query private var accounts: [Account]
  @Query private var notes: [Note]

  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @State private var collapsedAccounts: Set<String> = []
  @Namespace private var noteNamespace
  @State private var selectedNote: Note?
  // Actual minY of each note card captured from the unselected masonry layout.
  // Frozen at selection time so expanded layout changes don't clobber them.
  @State private var noteMinYs: [String: NoteFrame] = [:]
  @State private var frozenNoteMinYs: [String: NoteFrame] = [:]

  var body: some View {
    if accounts.isEmpty {
      EmptyAccountsView()
    } else {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(accounts) { account in
            let isCollapsed = collapsedAccounts.contains(account.email)

            HStack(spacing: 8) {
              HStack(spacing: 6) {
                CachedProfileImageView(
                  account: account,
                  isSyncing: AccountService.shared.syncingAccounts.contains(account.email),
                  errorMessage: AccountService.shared.errorMessages[account.email]
                )
                Text(account.email)
                  .font(.subheadline)
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                  .animation(.easeInOut(duration: 0.2), value: isCollapsed)
              }
              .contentShape(Rectangle())
              .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                  if isCollapsed {
                    collapsedAccounts.remove(account.email)
                  } else {
                    collapsedAccounts.insert(account.email)
                  }
                }
              }
              Spacer()
              Button {
                addBlankNote(for: account)
              } label: {
                Image(systemName: "document.badge.plus")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
              .help("New Note")
              Menu {
                Button(action: { AccountService.shared.deleteAccount(account) }) {
                  Text("Delete Account")
                }
              } label: {
                Image(systemName: "xmark")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .menuStyle(.borderlessButton)
              .menuIndicator(.hidden)
              .help("Delete Account")
              .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !isCollapsed {
              let accountNotes = NoteService.shared.getRootNotes(notes: notes, email: account.email)
              if !accountNotes.isEmpty {
                noteSection(accountNotes: accountNotes, account: account)
                  .padding(.horizontal, 12)
                  .padding(.bottom, 8)
                  .transition(.opacity)
              }
            }

            if account.id != accounts.last?.id {
              Divider()
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onPreferenceChange(NoteMinYKey.self) { noteMinYs = $0 }
      .onChange(of: selectedNote) { oldNote, newNote in
        NoteSelectionState.shared.noteIsSelected = newNote != nil
        if newNote == nil, let deselected = oldNote,
          let account = accounts.first(where: { $0.email == deselected.email }),
          notes.contains(where: { $0.email == account.email && $0.isDirty })
        {
          Task { await AccountService.shared.syncAccount(account) }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .deselectNote)) { _ in
        withAnimation(.spring(duration: 0.2)) { selectedNote = nil }
      }
    }
  }

  private func addBlankNote(for account: Account) {
    let noteId = String(format: "%.9f", Date().timeIntervalSince1970 * 1000)
    let childId =
      "sct." + String((0..<12).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
    let note = Note(
      email: account.email,
      id: noteId,
      parentId: "root",
      type: "NOTE",
      sortValue: "1000000000"
    )
    note.isDirty = true
    modelContext.insert(note)
    let child = Note(
      email: account.email,
      id: childId,
      parentId: noteId,
      type: "LIST_ITEM",
      sortValue: "1000000000"
    )
    child.isDirty = true
    modelContext.insert(child)
    if collapsedAccounts.contains(account.email) {
      _ = withAnimation(.easeInOut(duration: 0.2)) {
        collapsedAccounts.remove(account.email)
      }
    }
    frozenNoteMinYs = noteMinYs
    withAnimation(.spring(duration: 0.2)) { selectedNote = note }
  }

  @ViewBuilder
  private func noteSection(accountNotes: [Note], account: Account) -> some View {
    if let selected = selectedNote,
      selected.email == account.email,
      let idx = accountNotes.firstIndex(where: { $0.id == selected.id })
    {
      ExpandedNoteSectionView(
        accountNotes: accountNotes,
        allNotes: notes,
        selected: selected,
        selectedIdx: idx,
        noteMinYs: frozenNoteMinYs,
        namespace: noteNamespace,
        onSelectNote: { note in
          frozenNoteMinYs = noteMinYs
          withAnimation(.spring(duration: 0.2)) { selectedNote = note }
        },
        onClose: { withAnimation(.spring(duration: 0.2)) { selectedNote = nil } }
      )
    } else {
      MasonryVStack(columns: 2, spacing: 8) {
        ForEach(accountNotes) { note in
          makeNoteCard(note, allNotes: notes)
            .background(
              GeometryReader { geo in
                let frame = geo.frame(in: .named("masonrySpace"))
                Color.clear.preference(
                  key: NoteMinYKey.self,
                  value: [note.id: NoteFrame(minY: frame.minY, maxY: frame.maxY)]
                )
              }
            )
            .matchedGeometryEffect(id: note.id, in: noteNamespace)
            .contentShape(Rectangle())
            .onTapGesture {
              frozenNoteMinYs = noteMinYs
              withAnimation(.spring(duration: 0.2)) { selectedNote = note }
            }
        }
      }
      .coordinateSpace(name: "masonrySpace")
    }
  }
}

struct NoteFrame: Equatable {
  let minY: CGFloat
  let maxY: CGFloat
}

struct NoteMinYKey: PreferenceKey {
  static var defaultValue: [String: NoteFrame] = [:]
  static func reduce(value: inout [String: NoteFrame], nextValue: () -> [String: NoteFrame]) {
    value.merge(nextValue()) { _, new in new }
  }
}

private func makeNoteCard(_ note: Note, allNotes: [Note]) -> some View {
  let (unchecked, checked, text) = resolveNoteContent(note, allNotes: allNotes)
  return NoteCardView(
    uncheckedItems: unchecked, checkedItems: checked, textContent: text, note: note)
}

private func resolveNoteContent(_ note: Note, allNotes: [Note]) -> ([String], [String], String) {
  if !note.checkedCheckboxesCount.isEmpty {
    if note.type == "LIST" {
      let items = note.indexableText.components(separatedBy: "\n")
      let checkedCount = max(0, Int(note.checkedCheckboxesCount) ?? 0)
      return (
        Array(items.prefix(items.count - checkedCount)), Array(items.suffix(checkedCount)), ""
      )
    }
    return ([], [], note.indexableText)
  }
  if note.type == "LIST" {
    let children = allNotes.filter { $0.parentId == note.id && $0.deletedAt.isEmpty }
      .sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
    return (
      children.filter { !$0.checked }.map(\.text), children.filter { $0.checked }.map(\.text), ""
    )
  }
  let childTexts = allNotes.filter { $0.parentId == note.id && $0.deletedAt.isEmpty }.map(\.text)
  return ([], [], childTexts.isEmpty ? note.text : childTexts.joined(separator: "\n"))
}

struct ExpandedNoteSectionView: View {
  let accountNotes: [Note]
  let allNotes: [Note]
  let selected: Note
  let selectedIdx: Int
  // Actual minY+maxY values captured from the unselected masonry layout.
  let noteMinYs: [String: NoteFrame]
  let namespace: Namespace.ID
  let onSelectNote: (Note) -> Void
  let onClose: () -> Void

  private var before: [Note] {
    guard let selFrame = noteMinYs[selected.id] else {
      // Fallback: all notes before selectedIdx
      return Array(accountNotes.prefix(selectedIdx))
    }
    let selectedMinY = selFrame.minY
    return accountNotes.filter { note in
      guard note.id != selected.id else { return false }
      guard let frame = noteMinYs[note.id] else {
        return (accountNotes.firstIndex(where: { $0.id == note.id }) ?? selectedIdx) < selectedIdx
      }
      // "before" = card ends completely above the selected card's top
      return frame.maxY <= selectedMinY
    }
  }

  private var after: [Note] {
    guard let selFrame = noteMinYs[selected.id] else {
      return Array(accountNotes.suffix(from: selectedIdx + 1))
    }
    let selectedMinY = selFrame.minY
    return accountNotes.filter { note in
      guard note.id != selected.id else { return false }
      guard let frame = noteMinYs[note.id] else {
        return (accountNotes.firstIndex(where: { $0.id == note.id }) ?? 0) > selectedIdx
      }
      // "after" = card overlaps with or starts at/below the selected card's top
      return frame.maxY > selectedMinY
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !before.isEmpty {
        MasonryVStack(columns: 2, spacing: 8) {
          ForEach(before) { note in
            makeNoteCard(note, allNotes: allNotes)
              .matchedGeometryEffect(id: note.id, in: namespace)
              .contentShape(Rectangle())
              .onTapGesture { onSelectNote(note) }
          }
        }
      }

      NoteDetailView(
        note: selected,
        allNotes: allNotes,
        namespace: namespace,
        onClose: onClose
      )

      if !after.isEmpty {
        MasonryVStack(columns: 2, spacing: 8) {
          ForEach(after) { note in
            makeNoteCard(note, allNotes: allNotes)
              .matchedGeometryEffect(id: note.id, in: namespace)
              .contentShape(Rectangle())
              .onTapGesture { onSelectNote(note) }
          }
        }
      }
    }
  }

}

private struct CachedProfileImageView: View {
  let account: Account
  var isSyncing: Bool = false
  var errorMessage: String? = nil

  @State private var image: NSImage? = nil
  @State private var isHoveringError: Bool = false

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .clipShape(Circle())
      } else {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 20, height: 20)
    .overlay {
      if isSyncing {
        Circle()
          .fill(.background.opacity(0.6))
        ProgressView()
          .controlSize(.small)
      } else if errorMessage != nil {
        Circle()
          .fill(.black.opacity(0.6))
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 10))
          .foregroundStyle(.yellow)
          .onHover { isHoveringError = $0 }
          .popover(isPresented: $isHoveringError) {
            Text(errorMessage!)
              .font(.caption)
              .padding(4)
          }
      }
    }
    .clipped()
    .task(id: account.email) {
      image = await GoogleApiClient.shared.getProfilePicture(for: account)
    }
  }
}

struct EmptyAccountsView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "note.text")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("Press the + button below to add an account")
        .multilineTextAlignment(.center)
        .bold()

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 4) {
          Image(systemName: "circle.fill")
            .font(.system(size: 4))
          Text("Play Service (Recommended)")
          Spacer()
        }
        Text("Uses unofficial API pretending to be an Android device")
          .foregroundStyle(.secondary)
          .font(.caption)
          .padding(.leading, 10)

        HStack(spacing: 4) {
          Image(systemName: "circle.fill")
            .font(.system(size: 4))
          Text("Chrome Profile (Alternative)")
          Spacer()
        }
        Text("Uses invisible Chrome test browser")
          .foregroundStyle(.secondary)
          .font(.caption)
          .padding(.leading, 10)
      }
      .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}
