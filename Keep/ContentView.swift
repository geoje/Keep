import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Account.email, order: .forward) private var accounts: [Account]
  @Query private var notes: [Note]

  @State private var showingAddAccount = false
  @State private var hoveredAccountEmail: String?
  @State private var selectedAccount: Account?
  @State private var showDeleteConfirm = false
  @State private var isLoadingNotes = false
  @State private var errorMessage: String? = nil

  private var accountService: AccountService { AccountService() }
  private var noteService: NoteService { NoteService() }

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
                HStack(spacing: 8) {
                  Text(account.email)
                    .font(.body)

                  if isLoadingNotes {
                    ProgressView()
                      .controlSize(.small)
                      .frame(width: 12, height: 12)
                  } else if errorMessage != nil {
                    Image(systemName: "exclamationmark.triangle")
                      .foregroundColor(.yellow)
                  }
                }

                if let errorMessage = errorMessage {
                  Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                  HStack(spacing: 4) {
                    Image(systemName: "document")
                      .font(.system(size: 12))
                      .foregroundStyle(.secondary)
                    Text("\(notes.filter { $0.email == account.email }.count)")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
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
                errorMessage = nil
                isLoadingNotes = true
                Task {
                  do {
                    let fetchedNotes = try await noteService.getNotes(for: account)
                    let existingNotes = try modelContext.fetch(FetchDescriptor<Note>()).filter {
                      $0.email == account.email
                    }
                    for note in existingNotes {
                      modelContext.delete(note)
                    }
                    for note in fetchedNotes {
                      modelContext.insert(note)
                    }
                    try modelContext.save()
                  } catch {
                    errorMessage = error.localizedDescription
                  }
                  isLoadingNotes = false
                }
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
