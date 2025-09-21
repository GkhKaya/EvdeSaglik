//
//  LabResultRecommendationHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct LabResultRecommendationHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: LabResultRecommendationHistoryViewModel
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: LabResultRecommendationHistoryViewModel(
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
                } else if viewModel.recommendations.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: NSLocalizedString("LabHistory.Empty.Title", comment: "No lab results yet"),
                        description: NSLocalizedString("LabHistory.Empty.Description", comment: "Your lab result analyses will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.recommendations, id: \.id) { recommendation in
                                LabResultRecommendationCard(recommendation: recommendation)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("LabHistory.Title", comment: "Lab Results"))
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
                await viewModel.loadRecommendations()
            }
        }
    }
}

// MARK: - Lab Result Recommendation Card
struct LabResultRecommendationCard: View {
    let recommendation: LabResultRecommendationHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("LabHistory.Card.Date", comment: "Date:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("LabHistory.Card.Time", comment: "Time:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.createdAt, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("LabHistory.Card.LabResults", comment: "Lab Results:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(recommendation.labResults.keys), id: \.self) { key in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(recommendation.labResults[key] ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("LabHistory.Card.Medications", comment: "Suggested Medications:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(recommendation.suggestedMedications, id: \.self) { medication in
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(medication)
                            .font(.subheadline)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("LabHistory.Card.NaturalSolutions", comment: "Natural Solutions:"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(recommendation.suggestedNaturalSolutions, id: \.self) { solution in
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(solution)
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
class LabResultRecommendationHistoryViewModel: ObservableObject {
    @Published var recommendations: [LabResultRecommendationHistory] = []
    @Published var isLoading: Bool = false
    
    private let firestoreManager: FirestoreManager
    private let authManager: FirebaseAuthManager
    
    init(firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self.firestoreManager = firestoreManager
        self.authManager = authManager
    }
    
    @MainActor
    func loadRecommendations() async {
        isLoading = true
        
        guard let userId = authManager.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            recommendations = try await firestoreManager.queryDocuments(
                from: "labResultRecommendations", 
                where: "userId", 
                isEqualTo: userId, 
                as: LabResultRecommendationHistory.self
            )
        } catch {
            print("Error loading lab result recommendation history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Data Model
typealias LabResultRecommendationHistory = LabResultRecommendationModel

// MARK: - Preview
#Preview {
    LabResultRecommendationHistoryView(
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
