import SwiftData
import SwiftUI

struct AccountRowView: View {
  let account: Account
  let isSelected: Bool
  let isLoading: Bool
  let errorMessage: String?
  let noteCount: Int
  @Binding var hoveredAccountEmail: String?
  let onTap: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      if !account.picture.isEmpty {
        AsyncImage(url: URL(string: account.picture)) { phase in
          switch phase {
          case .empty:
            Circle()
              .fill(Color.gray.opacity(0.15))
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: "person.fill")
                  .font(.system(size: 18))
                  .foregroundStyle(.gray)
              }
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(width: 40, height: 40)
              .clipShape(Circle())
          case .failure:
            Circle()
              .fill(Color.gray.opacity(0.15))
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: "person.fill")
                  .font(.system(size: 18))
                  .foregroundStyle(.gray)
              }
          @unknown default:
            Circle()
              .fill(Color.gray.opacity(0.15))
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: "person.fill")
                  .font(.system(size: 18))
                  .foregroundStyle(.gray)
              }
          }
        }
      } else {
        Circle()
          .fill(Color.gray.opacity(0.15))
          .frame(width: 40, height: 40)
          .overlay {
            Image(systemName: "person.fill")
              .font(.system(size: 18))
              .foregroundStyle(.gray)
          }
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(account.email)
            .font(.body)

          if isLoading {
            ProgressView()
              .controlSize(.small)
              .frame(width: 12, height: 12)
          } else if errorMessage != nil {
            Image(systemName: "exclamationmark.triangle")
              .foregroundColor(.yellow)
          }
        }

        bottomView
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 8)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets())
    .background(
      Capsule()
        .fill(
          isSelected
            ? Color.accentColor.opacity(0.2)
            : (hoveredAccountEmail == account.email ? Color.gray.opacity(0.1) : Color.clear)
        )
    )
    .onHover { hovering in
      hoveredAccountEmail = hovering ? account.email : nil
    }
    .onTapGesture {
      onTap()
    }
  }

  private var bottomView: some View {
    if let errorMessage = errorMessage {
      return AnyView(
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.secondary)
      )
    } else {
      return AnyView(
        HStack(spacing: 16) {
          HStack(spacing: 4) {
            Image(systemName: "document")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
            Text("\(noteCount)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 4) {
            if !account.masterToken.isEmpty {
              Image(systemName: "key")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            if !account.profileName.isEmpty {
              Image(systemName: "person")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
          }
        }
      )
    }
  }
}
