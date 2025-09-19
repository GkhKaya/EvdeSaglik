//
//  HomeSolutionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct HomeSolutionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel = HomeSolutionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Common.Loading", comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.solutions.isEmpty {
                    VStack(spacing: ResponsivePadding.large) {
                        Image(systemName: "house")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(NSLocalizedString("HomeHistory.Empty.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("HomeHistory.Empty.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsivePadding.large)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.solutions) { solution in
                                HomeSolutionHistoryCard(solution: solution)
                            }
                        }
                        .padding(ResponsivePadding.large)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("HomeHistory.Title", comment: ""))
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

struct HomeSolutionHistoryCard: View {
    let solution: HomeSolutionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            // Header with date
            HStack {
                Text(NSLocalizedString("HomeHistory.Card.Date", comment: ""))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(solution.createdAt, style: .date)
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Symptom
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("HomeHistory.Card.Symptom", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                Text(solution.symptom)
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Solutions
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("HomeHistory.Card.Solutions", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                ForEach(solution.solutions, id: \.title) { solutionItem in
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        Text(solutionItem.title)
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                        
                        Text(solutionItem.description)
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                    }
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

final class HomeSolutionHistoryViewModel: ObservableObject {
    @Published var solutions: [HomeSolutionModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadSolutions(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        guard let userId = authManager.currentUser?.uid else { return }
        
        isLoading = true
        
        firestoreManager.queryDocuments(collection: "homeSolutions", field: "userId", isEqualTo: userId) { [weak self] (result: Result<[HomeSolutionModel], AppError>) in
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

