//
//  HomeSolutionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct HomeSolutionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: HomeSolutionHistoryViewModel
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: HomeSolutionHistoryViewModel(
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
                        icon: "house",
                        title: NSLocalizedString("HomeHistory.Empty.Title", comment: "No home solutions yet"),
                        description: NSLocalizedString("HomeHistory.Empty.Description", comment: "Your home solutions will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.solutions, id: \.id) { solution in
                                HomeSolutionCard(solution: solution)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("HomeHistory.Title", comment: "Home Solutions"))
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

// MARK: - Home Solution Card
struct HomeSolutionCard: View {
    let solution: HomeSolutionHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("HomeHistory.Card.Date", comment: "Date:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(solution.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("HomeHistory.Card.Time", comment: "Time:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(solution.createdAt, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("HomeHistory.Card.Problem", comment: "Problem:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(solution.symptom)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("HomeHistory.Card.Solutions", comment: "Home Solutions:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(solution.solutions, id: \.title) { solutionItem in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(solutionItem.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(solutionItem.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
class HomeSolutionHistoryViewModel: ObservableObject {
    @Published var solutions: [HomeSolutionHistory] = []
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
                from: "homeSolutions", 
                where: "userId", 
                isEqualTo: userId, 
                as: HomeSolutionHistory.self
            )
        } catch {
            print("Error loading home solution history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Data Model
typealias HomeSolutionHistory = HomeSolutionModel

// MARK: - Preview
#Preview {
    HomeSolutionHistoryView(
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
