import SwiftUI

struct AccountListView: View {
  let accounts: [Account]
  let notes: [Note]
  let onDelete: (Account) -> Void

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(accounts) { account in
          HStack(spacing: 8) {
            accountAvatar(account)
            Text(account.email)
              .font(.subheadline)
            Spacer()
            Menu {
              Button(action: { onDelete(account) }) {
                Text("Delete Account")
              }
            } label: {
              Image(systemName: "trash")
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)

          let accountNotes = NoteService.shared.getRootNotes(notes: notes, email: account.email)
          if !accountNotes.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
              ForEach(accountNotes) { note in
                noteCard(note, allNotes: notes)
              }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
          }

          Divider()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Note Card

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
      for n in allNotes where n.parentId == note.id {
        if n.checked { checked.append(n.text) } else { unchecked.append(n.text) }
      }
      return (unchecked, checked, "")
    }

    let childTexts = allNotes.filter { $0.parentId == note.id }.map { $0.text }
    let text = childTexts.isEmpty ? note.text : childTexts.joined(separator: "\n")
    return ([], [], text)
  }

  // MARK: - Account Avatar

  private func accountAvatar(_ account: Account) -> some View {
    Group {
      if !account.picture.isEmpty, let url = URL(string: account.picture) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image.resizable().scaledToFill()
              .frame(width: 20, height: 20)
              .clipShape(Circle())
          default:
            placeholderAvatar
          }
        }
        .frame(width: 20, height: 20)
      } else {
        placeholderAvatar
      }
    }
  }

  private var placeholderAvatar: some View {
    Image(systemName: "person.crop.circle.fill")
      .font(.system(size: 16))
      .foregroundStyle(.secondary)
      .frame(width: 20, height: 20)
  }
}

private struct NoteCardView: View {
  let uncheckedItems: [String]
  let checkedItems: [String]
  let textContent: String
  let note: Note

  @Environment(\.colorScheme) var colorScheme
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if !note.title.isEmpty {
        Text(note.title)
          .font(.headline)
          .foregroundColor(.primary)
      }
      if uncheckedItems.isEmpty && checkedItems.isEmpty {
        if !textContent.isEmpty {
          Text(textContent)
            .font(.body)
            .foregroundColor(.primary)
        }
      } else {
        if !uncheckedItems.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(uncheckedItems.indices, id: \.self) { index in
              HStack(spacing: 4) {
                Image(systemName: "square")
                  .font(.body)
                  .foregroundColor(.secondary)
                  .opacity(0.4)
                Text(uncheckedItems[index])
                  .font(.body)
                  .foregroundColor(.primary)
              }
            }
          }
        }
        if !checkedItems.isEmpty {
          Text("+ \(checkedItems.count) checked item\(checkedItems.count > 1 ? "s" : "")")
            .font(.body)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(10)
    .background(NoteService.shared.noteColor(for: note.color, colorScheme: colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(Color.primary.opacity(isHovered ? 0.4 : 0), lineWidth: 1)
    )
    .onHover { isHovered = $0 }
  }
}
