import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Account.email, order: .forward) private var accounts: [Account]
  @State private var showingAddAccount = false
  @State private var hoveredAccountEmail: String?
  @State private var selectedAccount: Account?
  @State private var showDeleteConfirm = false

  var body: some View {
    Group {
      if accounts.isEmpty {
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
      } else {
        List {
          ForEach(accounts) { account in
            HStack(spacing: 12) {
              Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                  Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
                }

              VStack(alignment: .leading, spacing: 4) {
                Text(account.email)
                  .font(.body)

                HStack(spacing: 4) {
                  Image(systemName: "document")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                  Text("0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
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
                  selectedAccount?.email == account.email
                    ? Color.accentColor.opacity(0.2)
                    : (hoveredAccountEmail == account.email ? Color.gray.opacity(0.1) : Color.clear)
                )
            )
            .onHover { hovering in
              hoveredAccountEmail = hovering ? account.email : nil
            }
            .onTapGesture {
              if selectedAccount?.email == account.email {
                selectedAccount = nil
              } else {
                selectedAccount = account
              }
            }
          }

        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
          Rectangle()
            .frame(height: 0)
        }
      }
    }
    .frame(minWidth: 360, maxWidth: 360, minHeight: 240)
    .alert("Delete Account", isPresented: $showDeleteConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let account = selectedAccount {
          modelContext.delete(account)
          selectedAccount = nil
        }
      }
    } message: {
      Text("Are you sure you want to delete this account?")
    }
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Spacer()
      }
      if selectedAccount != nil {
        ToolbarItem(placement: .automatic) {
          Button(action: {
            showDeleteConfirm = true
          }) {
            Label("Delete", systemImage: "trash")
              .foregroundStyle(.red)
          }
        }
      }
      ToolbarItem(placement: .automatic) {
        Button(action: {
          showingAddAccount = true
        }) {
          Label("Add", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showingAddAccount) {
      AddAccountView()
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Account.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  let context = container.mainContext

  let emails = [
    "alice@google.com",
    "bob@gmail.com",
    "charlie@outlook.com",
    "david@icloud.com",
    "emma@yahoo.com",
    "frank@proton.me",
    "grace@hotmail.com",
    "henry@example.com",
  ]

  for (index, email) in emails.enumerated() {
    let account = Account(email: email, avatar: "", masterToken: "aas_et/\(index)")
    context.insert(account)
  }

  return ContentView()
    .modelContainer(container)
}
