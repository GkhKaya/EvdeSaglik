//
//  DiseasePredictionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct DiseasePredictionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel = DiseasePredictionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Common.Loading", comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.predictions.isEmpty {
                    VStack(spacing: ResponsivePadding.large) {
                        Image(systemName: "cross.case")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(NSLocalizedString("DiseaseHistory.Empty.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("DiseaseHistory.Empty.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsivePadding.large)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.predictions) { prediction in
                                DiseasePredictionHistoryCard(prediction: prediction)
                            }
                        }
                        .padding(ResponsivePadding.large)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("DiseaseHistory.Title", comment: ""))
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
                viewModel.loadPredictions(authManager: authManager, firestoreManager: firestoreManager)
            }
        }
    }
}

struct DiseasePredictionHistoryCard: View {
    let prediction: DiseasePredictionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            // Header with date
            HStack {
                Text(NSLocalizedString("DiseaseHistory.Card.Date", comment: ""))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(prediction.createdAt, style: .date)
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Symptoms
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("DiseaseHistory.Card.Symptoms", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                Text(prediction.symptoms.joined(separator: ", "))
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Disease predictions
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("DiseaseHistory.Card.Predictions", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                ForEach(prediction.possibleDiseases, id: \.name) { disease in
                    HStack {
                        Text(disease.name)
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(disease.probability * 100))%")
                            .font(.bodyResponsive)
                            .foregroundStyle(.orange)
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
        }
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray).opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

final class DiseasePredictionHistoryViewModel: ObservableObject {
    @Published var predictions: [DiseasePredictionModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadPredictions(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        guard let userId = authManager.currentUser?.uid else { return }
        
        isLoading = true
        
        firestoreManager.queryDocuments(collection: "diseasePredictions", field: "userId", isEqualTo: userId) { [weak self] (result: Result<[DiseasePredictionModel], AppError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let predictions):
                    self?.predictions = predictions.sorted { $0.createdAt > $1.createdAt }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

