import SwiftUI

struct EmptyAccountsView: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 80))
        .foregroundStyle(.gray.opacity(0.3))

      VStack(spacing: 8) {
        Text("No accounts yet")
          .font(.title3)
          .foregroundStyle(.secondary)

        Text("Click the + button above to add an account")
          .font(.body)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
