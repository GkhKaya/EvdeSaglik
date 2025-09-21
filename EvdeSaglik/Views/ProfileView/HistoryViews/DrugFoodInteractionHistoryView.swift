//
//  DrugFoodInteractionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct DrugFoodInteractionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DrugFoodInteractionHistoryViewModel
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: DrugFoodInteractionHistoryViewModel(
            firestoreManager: firestoreManager,
            authManager: authManager
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Loading.Loading", comment: "Loading"))
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.interactions.isEmpty {
                    EmptyStateView(
                        icon: "pills",
                        title: NSLocalizedString("DrugFoodInteractionHistory.Empty.Title", comment: "No interactions yet"),
                        description: NSLocalizedString("DrugFoodInteractionHistory.Empty.Description", comment: "Your drug-food interactions will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.interactions, id: \.id) { interaction in
                                DrugFoodInteractionCard(interaction: interaction)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("DrugFoodInteractionHistory.Title", comment: "Drug-Food Interactions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Common.Close", comment: "Close")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInteractions()
            }
        }
    }
}

// MARK: - Drug Food Interaction Card
struct DrugFoodInteractionCard: View {
    let interaction: DrugFoodInteractionHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Date", comment: "Date:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interaction.timestamp, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Time", comment: "Time:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interaction.timestamp, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Drug", comment: "Drug:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(interaction.drugName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Food", comment: "Food:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(interaction.foodName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Interaction", comment: "Interaction:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(interaction.interactionResult)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DrugFoodInteractionHistory.Card.Summary", comment: "Summary:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(interaction.userSummary)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View Model
class DrugFoodInteractionHistoryViewModel: ObservableObject {
    @Published var interactions: [DrugFoodInteractionHistory] = []
    @Published var isLoading: Bool = false
    
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
    }
    
    @MainActor
    func loadInteractions() async {
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            interactions = try await firestoreManager.queryDocuments(
                from: "drugFoodInteractions", 
                where: "userId", 
                isEqualTo: userId, 
                as: DrugFoodInteractionHistory.self
            )
        } catch {
            print("Error loading drug-food interaction history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Data Model
typealias DrugFoodInteractionHistory = DrugFoodInteractionModel

// MARK: - Preview
#Preview {
    DrugFoodInteractionHistoryView(
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
