//
//  DiseasePredictionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct DiseasePredictionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DiseasePredictionHistoryViewModel
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: DiseasePredictionHistoryViewModel(
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
                } else if viewModel.predictions.isEmpty {
                    EmptyStateView(
                        icon: "cross.case",
                        title: NSLocalizedString("DiseaseHistory.Empty.Title", comment: "No disease predictions yet"),
                        description: NSLocalizedString("DiseaseHistory.Empty.Description", comment: "Your disease predictions will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.predictions, id: \.id) { prediction in
                                DiseasePredictionCard(prediction: prediction)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("DiseaseHistory.Title", comment: "Disease Predictions"))
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
                await viewModel.loadPredictions()
            }
        }
    }
}

// MARK: - Disease Prediction Card
struct DiseasePredictionCard: View {
    let prediction: DiseasePredictionHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("DiseaseHistory.Card.Date", comment: "Date:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prediction.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("DiseaseHistory.Card.Time", comment: "Time:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prediction.createdAt, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DiseaseHistory.Card.Symptoms", comment: "Symptoms:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(prediction.symptoms.joined(separator: ", "))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("DiseaseHistory.Card.Predictions", comment: "Predicted Diseases:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(prediction.possibleDiseases.enumerated()), id: \.offset) { index, disease in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(confidenceColor(disease.probability))
                                .frame(width: 20, height: 20)
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(disease.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(Int(disease.probability * 100))% confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func confidenceColor(_ probability: Double) -> Color {
        let percentage = probability * 100
        switch percentage {
        case 80...100:
            return .red
        case 60..<80:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .gray
        }
    }
}

// MARK: - View Model
class DiseasePredictionHistoryViewModel: ObservableObject {
    @Published var predictions: [DiseasePredictionHistory] = []
    @Published var isLoading: Bool = false
    
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
    }
    
    @MainActor
    func loadPredictions() async {
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            predictions = try await firestoreManager.queryDocuments(
                from: "diseasePredictions", 
                where: "userId", 
                isEqualTo: userId, 
                as: DiseasePredictionHistory.self
            )
        } catch {
            print("Error loading disease prediction history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Data Model
typealias DiseasePredictionHistory = DiseasePredictionModel

// MARK: - Preview
#Preview {
    DiseasePredictionHistoryView(
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
