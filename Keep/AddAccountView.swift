import SwiftData
import SwiftUI

struct AddAccountView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var email: String = ""
  @State private var oauthToken: String = ""

  var body: some View {
    VStack(spacing: 12) {
      Text("Add Account")
        .font(.title3)
        .bold()
        .foregroundStyle(.primary.opacity(0.9))

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          Image(systemName: "envelope.fill")
            .foregroundStyle(.secondary)
            .frame(width: 16)
          Text("Email")
            .font(.headline)
        }
        TextField("example@google.com", text: $email)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal, 0)
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          Image(systemName: "key.fill")
            .foregroundStyle(.secondary)
            .frame(width: 16)
          Text("OAuth Token")
            .font(.headline)
          Spacer()
          Link(
            destination: URL(
              string: "https://github.com/rukins/gpsoauth-java?tab=readme-ov-file#second-way")!
          ) {
            Image(systemName: "questionmark.circle")
              .foregroundStyle(.gray.opacity(0.5))
          }
          .help("Click to learn how to get your OAuth token")
          .contentShape(Rectangle())
          .onHover { hovering in
            if hovering {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }
        }
        SecureField("oauth2_4/", text: $oauthToken)
          .textFieldStyle(.roundedBorder)
          .textContentType(.oneTimeCode)
          .disableAutocorrection(true)
          .padding(.horizontal, 0)
      }

      Spacer()

      HStack(spacing: 8) {
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)

        Button("Add") {
          addAccount()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(email.isEmpty || oauthToken.isEmpty)
      }
    }
    .padding()
    .frame(width: 300)
  }

  private func addAccount() {
    let newAccount = Account(email: email, avatar: oauthToken)
    modelContext.insert(newAccount)
    dismiss()
  }
}

#Preview {
  AddAccountView()
    .modelContainer(for: Account.self, inMemory: true)
}
