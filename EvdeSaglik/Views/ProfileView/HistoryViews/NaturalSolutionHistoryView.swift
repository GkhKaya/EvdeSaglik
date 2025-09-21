//
//  NaturalSolutionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct NaturalSolutionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NaturalSolutionHistoryViewModel
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: NaturalSolutionHistoryViewModel(
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
                } else if viewModel.solutions.isEmpty {
                    EmptyStateView(
                        icon: "leaf.fill",
                        title: NSLocalizedString("NaturalHistory.Empty.Title", comment: "No natural solutions yet"),
                        description: NSLocalizedString("NaturalHistory.Empty.Description", comment: "Your natural remedy suggestions will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.solutions, id: \.id) { solution in
                                NaturalSolutionCard(solution: solution)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("NaturalHistory.Title", comment: "Natural Solutions"))
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
                await viewModel.loadSolutions()
            }
        }
    }
}

// MARK: - Natural Solution Card
struct NaturalSolutionCard: View {
    let solution: NaturalSolutionHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("NaturalHistory.Card.Date", comment: "Date:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(solution.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("NaturalHistory.Card.Time", comment: "Time:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(solution.createdAt, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("NaturalHistory.Card.Condition", comment: "Condition:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(solution.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("NaturalHistory.Card.Solutions", comment: "Natural Solutions:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(solution.remedies, id: \.self) { remedy in
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(remedy)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Model
class NaturalSolutionHistoryViewModel: ObservableObject {
    @Published var solutions: [NaturalSolutionHistory] = []
    @Published var isLoading: Bool = false
    
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
    }
    
    @MainActor
    func loadSolutions() async {
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            solutions = try await firestoreManager.queryDocuments(
                from: "naturalSolutions", 
                where: "userId", 
                isEqualTo: userId, 
                as: NaturalSolutionHistory.self
            )
        } catch {
            print("Error loading natural solution history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Data Model
typealias NaturalSolutionHistory = NaturalSolitionsModel

// MARK: - Preview
#Preview {
    NaturalSolutionHistoryView(
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
