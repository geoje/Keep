import SwiftData
import SwiftUI

struct AddAccountView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var email: String = ""
  @State private var oauthToken: String = ""
  @State private var isLoading = false
  @State private var errorMessage: String? = nil

  let onAccountAdded: ((Account) -> Void)?

  init(onAccountAdded: ((Account) -> Void)? = nil) {
    self.onAccountAdded = onAccountAdded
  }

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
        TextField("example@gmail.com", text: $email)
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
        ZStack(alignment: .topLeading) {
          TextEditor(text: $oauthToken)
            .padding(.vertical, 8)
            .frame(height: 60)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
          if oauthToken.isEmpty {
            Text("oauth2_4/")
              .padding(5)
              .font(.system(size: 11))
              .foregroundColor(.gray)
              .allowsHitTesting(false)
          }
        }
      }

      HStack(spacing: 8) {
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)

        Button(action: {
          Task {
            await addAccount()
          }
        }) {
          if isLoading {
            ProgressView()
              .controlSize(.small)
          } else {
            Text("Add")
          }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(isLoading || email.isEmpty || oauthToken.isEmpty)
      }

      Divider()

      Button("Sign in with Google") {
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(width: 300)
    .alert(
      "⚠️ Authentication Error",
      isPresented: Binding(
        get: { errorMessage != nil },
        set: { if !$0 { errorMessage = nil } }
      )
    ) {
      Button("OK") {}
    } message: {
      Text(errorMessage ?? "Unknown error")
    }
  }

  private func addAccount() async {
    isLoading = true
    let authService = GoogleAuthService()

    do {
      let masterToken = try await authService.fetchMasterToken(email: email, oauthToken: oauthToken)
      let newAccount = Account(email: email, picture: "", masterToken: masterToken)
      modelContext.insert(newAccount)
      try modelContext.save()
      onAccountAdded?(newAccount)
      dismiss()
    } catch {
      self.errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}

#Preview {
  AddAccountView()
    .modelContainer(for: Account.self)
}
