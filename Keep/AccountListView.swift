import SwiftUI

struct AccountListView: View {
  let accounts: [Account]
  let notes: [Note]
  let syncingAccounts: Set<String>
  let errorMessages: [String: String]
  let onDelete: (Account) -> Void

  @Environment(\.colorScheme) var colorScheme
  @State private var collapsedAccounts: Set<String> = []
  @Namespace private var noteNamespace
  @State private var selectedNote: Note?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(accounts) { account in
          let isCollapsed = collapsedAccounts.contains(account.email)

          HStack(spacing: 8) {
            HStack(spacing: 6) {
              CachedProfileImageView(account: account)
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
            if let errorMessage = errorMessages[account.email] {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
                .padding(6)
                .contentShape(Rectangle())
                .help(errorMessage)
            }
            if syncingAccounts.contains(account.email) {
              ProgressView()
                .scaleEffect(0.4)
                .frame(width: 12, height: 12)
            }
            Spacer()
            Menu {
              Button(action: { onDelete(account) }) {
                Text("Delete Account")
              }
            } label: {
              Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
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
    .onChange(of: selectedNote) { _, note in
      NoteSelectionState.shared.noteIsSelected = note != nil
    }
    .onReceive(NotificationCenter.default.publisher(for: .deselectNote)) { _ in
      withAnimation(.spring(duration: 0.2)) { selectedNote = nil }
    }
  }

  @ViewBuilder
  private func noteSection(accountNotes: [Note], account: Account) -> some View {
    if let selected = selectedNote,
      selected.email == account.email,
      let idx = accountNotes.firstIndex(where: { $0.id == selected.id })
    {
      let before = Array(accountNotes.prefix(idx))
      let after = Array(accountNotes.suffix(from: idx + 1))

      VStack(alignment: .leading, spacing: 8) {
        if !before.isEmpty {
          MasonryVStack(columns: 2, spacing: 8) {
            ForEach(before) { note in
              noteCard(note, allNotes: notes)
                .matchedGeometryEffect(id: note.id, in: noteNamespace)
                .contentShape(Rectangle())
                .onTapGesture {
                  withAnimation(.spring(duration: 0.2)) { selectedNote = note }
                }
            }
          }
        }

        NoteDetailView(
          note: selected,
          allNotes: notes,
          namespace: noteNamespace,
          onClose: { withAnimation(.spring(duration: 0.2)) { selectedNote = nil } }
        )

        if !after.isEmpty {
          MasonryVStack(columns: 2, spacing: 8) {
            ForEach(after) { note in
              noteCard(note, allNotes: notes)
                .matchedGeometryEffect(id: note.id, in: noteNamespace)
                .contentShape(Rectangle())
                .onTapGesture {
                  withAnimation(.spring(duration: 0.2)) { selectedNote = note }
                }
            }
          }
        }
      }
    } else {
      MasonryVStack(columns: 2, spacing: 8) {
        ForEach(accountNotes) { note in
          noteCard(note, allNotes: notes)
            .matchedGeometryEffect(id: note.id, in: noteNamespace)
            .contentShape(Rectangle())
            .onTapGesture {
              withAnimation(.spring(duration: 0.2)) { selectedNote = note }
            }
        }
      }
    }
  }

  private func noteCard(_ note: Note, allNotes: [Note]) -> some View {
    let (uncheckedItems, checkedItems, textContent) = noteContent(note, allNotes: allNotes)
    return NoteCardView(
      uncheckedItems: uncheckedItems,
      checkedItems: checkedItems,
      textContent: textContent,
      note: note
    )
  }

  private func noteContent(_ note: Note, allNotes: [Note]) -> (
    unchecked: [String], checked: [String], text: String
  ) {
    if !note.checkedCheckboxesCount.isEmpty {
      if note.type == "LIST" {
        let items = note.indexableText.components(separatedBy: "\n")
        let checkedCount = max(0, Int(note.checkedCheckboxesCount) ?? 0)
        let checked = Array(items.suffix(checkedCount))
        let unchecked = Array(items.prefix(items.count - checkedCount))
        return (unchecked, checked, "")
      }
      return ([], [], note.indexableText)
    }

    if note.type == "LIST" {
      var unchecked: [String] = []
      var checked: [String] = []
      let children = allNotes.filter { $0.parentId == note.id }
        .sorted { (Int($0.sortValue) ?? 0) > (Int($1.sortValue) ?? 0) }
      for n in children {
        if n.checked { checked.append(n.text) } else { unchecked.append(n.text) }
      }
      return (unchecked, checked, "")
    }

    let childTexts = allNotes.filter { $0.parentId == note.id }.map { $0.text }
    let text = childTexts.isEmpty ? note.text : childTexts.joined(separator: "\n")
    return ([], [], text)
  }

}

private struct CachedProfileImageView: View {
  let account: Account

  @State private var image: NSImage? = nil

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 20, height: 20)
          .clipShape(Circle())
      } else {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
          .frame(width: 20, height: 20)
      }
    }
    .task(id: account.email) {
      image = await GoogleApiClient.shared.getProfilePicture(for: account)
    }
  }
}
