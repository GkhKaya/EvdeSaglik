//
//  LabResultHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct LabResultHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel = LabResultHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Common.Loading", comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.results.isEmpty {
                    VStack(spacing: ResponsivePadding.large) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(NSLocalizedString("LabHistory.Empty.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("LabHistory.Empty.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsivePadding.large)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.results) { result in
                                LabResultHistoryCard(result: result)
                            }
                        }
                        .padding(ResponsivePadding.large)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("LabHistory.Title", comment: ""))
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
                viewModel.loadResults(authManager: authManager, firestoreManager: firestoreManager)
            }
        }
    }
}

struct LabResultHistoryCard: View {
    let result: LabResultRecommendationModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            // Header with date
            HStack {
                Text(NSLocalizedString("LabHistory.Card.Date", comment: ""))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(result.createdAt, style: .date)
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Lab results
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("LabHistory.Card.Results", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                ForEach(Array(result.labResults.keys.sorted()), id: \.self) { testName in
                    HStack {
                        Text(testName)
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(result.labResults[testName] ?? 0, specifier: "%.1f")")
                            .font(.bodyResponsive)
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, ResponsivePadding.small)
                    .padding(.horizontal, ResponsivePadding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveRadius.small)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Suggested medications
            if !result.suggestedMedications.isEmpty {
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("LabHistory.Card.Medications", comment: ""))
                        .font(.subheadlineResponsive)
                        .fontWeight(.semibold)
                    
                    ForEach(result.suggestedMedications, id: \.self) { medication in
                        Text("• \(medication)")
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Suggested natural solutions
            if !result.suggestedNaturalSolutions.isEmpty {
                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                    Text(NSLocalizedString("LabHistory.Card.NaturalSolutions", comment: ""))
                        .font(.subheadlineResponsive)
                        .fontWeight(.semibold)
                    
                    ForEach(result.suggestedNaturalSolutions, id: \.self) { solution in
                        Text("• \(solution)")
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                    }
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

final class LabResultHistoryViewModel: ObservableObject {
    @Published var results: [LabResultRecommendationModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadResults(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        guard let userId = authManager.currentUser?.uid else { return }
        
        isLoading = true
        
        firestoreManager.queryDocuments(collection: "labResultRecommendations", field: "userId", isEqualTo: userId) { [weak self] (result: Result<[LabResultRecommendationModel], AppError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let results):
                    self?.results = results.sorted { $0.createdAt > $1.createdAt }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

