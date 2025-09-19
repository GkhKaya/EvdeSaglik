//
//  NaturalSolutionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct NaturalSolutionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel = NaturalSolutionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Common.Loading", comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.solutions.isEmpty {
                    VStack(spacing: ResponsivePadding.large) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(NSLocalizedString("NaturalHistory.Empty.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("NaturalHistory.Empty.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsivePadding.large)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.solutions) { solution in
                                NaturalSolutionHistoryCard(solution: solution)
                            }
                        }
                        .padding(ResponsivePadding.large)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("NaturalHistory.Title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodyResponsive)
                    }
                }
            }
            .onAppear {
                viewModel.loadSolutions(authManager: authManager, firestoreManager: firestoreManager)
            }
        }
    }
}

struct NaturalSolutionHistoryCard: View {
    let solution: NaturalSolitionsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            // Header with date
            HStack {
                Text(NSLocalizedString("NaturalHistory.Card.Date", comment: ""))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(solution.createdAt, style: .date)
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Question
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("NaturalHistory.Card.Question", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                Text(solution.question)
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Remedies
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("NaturalHistory.Card.Remedies", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                ForEach(solution.remedies, id: \.self) { remedy in
                    Text("• \(remedy)")
                        .font(.bodyResponsive)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, ResponsivePadding.small)
                        .padding(.horizontal, ResponsivePadding.medium)
                        .background(
                            RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray).opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

final class NaturalSolutionHistoryViewModel: ObservableObject {
    @Published var solutions: [NaturalSolitionsModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadSolutions(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        guard let userId = authManager.currentUser?.uid else { return }
        
        isLoading = true
        
        firestoreManager.queryDocuments(collection: "naturalSolutions", field: "userId", isEqualTo: userId) { [weak self] (result: Result<[NaturalSolitionsModel], AppError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let solutions):
                    self?.solutions = solutions.sorted { $0.createdAt > $1.createdAt }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

