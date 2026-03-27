import SwiftUI

struct AccountListView: View {
  let accounts: [Account]
  let onDelete: (Account) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(accounts) { account in
          HStack(spacing: 8) {
            accountAvatar(account)
            Text(account.email)
              .font(.subheadline)
            Spacer()
            Button(action: { onDelete(account) }) {
              Image(systemName: "trash")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          Divider()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

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
