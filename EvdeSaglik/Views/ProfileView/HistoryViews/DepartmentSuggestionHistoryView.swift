//
//  DepartmentSuggestionHistoryView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI

struct DepartmentSuggestionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @StateObject private var viewModel = DepartmentSuggestionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Common.Loading", comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.suggestions.isEmpty {
                    VStack(spacing: ResponsivePadding.large) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(NSLocalizedString("DepartmentHistory.Empty.Title", comment: ""))
                            .font(.title2Responsive)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("DepartmentHistory.Empty.Description", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(ResponsivePadding.large)
                } else {
                    ScrollView {
                        LazyVStack(spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.suggestions) { suggestion in
                                DepartmentSuggestionHistoryCard(suggestion: suggestion)
                            }
                        }
                        .padding(ResponsivePadding.large)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("DepartmentHistory.Title", comment: ""))
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
                viewModel.loadSuggestions(authManager: authManager, firestoreManager: firestoreManager)
            }
        }
    }
}

struct DepartmentSuggestionHistoryCard: View {
    let suggestion: DepartmentSuggestionModel
    
    /// Parses department name and confidence from the stored string format
    /// Format: "Department Name (85%)"
    private func parseDepartmentWithConfidence(_ departmentWithConfidence: String) -> (String, String) {
        // Look for pattern like "Department Name (85%)"
        let pattern = #"^(.+?)\s*\((\d+)%\)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        if let regex = regex {
            let range = NSRange(location: 0, length: departmentWithConfidence.utf16.count)
            if let match = regex.firstMatch(in: departmentWithConfidence, options: [], range: range),
               match.numberOfRanges == 3,
               let nameRange = Range(match.range(at: 1), in: departmentWithConfidence),
               let confidenceRange = Range(match.range(at: 2), in: departmentWithConfidence) {
                
                let departmentName = String(departmentWithConfidence[nameRange]).trimmingCharacters(in: .whitespaces)
                let confidence = String(departmentWithConfidence[confidenceRange])
                return (departmentName, "\(confidence)%")
            }
        }
        
        // Fallback: return the original string as department name
        return (departmentWithConfidence, "Önerilen")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
            // Header with date
            HStack {
                Text(NSLocalizedString("DepartmentHistory.Card.Date", comment: ""))
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(suggestion.createdAt, style: .date)
                    .font(.captionResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Symptoms
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("DepartmentHistory.Card.Symptoms", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                Text(suggestion.symptoms.joined(separator: ", "))
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
            }
            
            // Department suggestions
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(NSLocalizedString("DepartmentHistory.Card.Suggestions", comment: ""))
                    .font(.subheadlineResponsive)
                    .fontWeight(.semibold)
                
                ForEach(Array(suggestion.suggestedDepartments.enumerated()), id: \.offset) { index, departmentWithConfidence in
                    let (departmentName, confidence) = parseDepartmentWithConfidence(departmentWithConfidence)
                    
                    HStack {
                        Text(departmentName)
                            .font(.bodyResponsive)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(confidence)
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
        }
        .padding(ResponsivePadding.medium)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray).opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

final class DepartmentSuggestionHistoryViewModel: ObservableObject {
    @Published var suggestions: [DepartmentSuggestionModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadSuggestions(authManager: FirebaseAuthManager, firestoreManager: FirestoreManager) {
        guard let userId = authManager.currentUser?.uid else { return }
        
        isLoading = true
        
        firestoreManager.queryDocuments(collection: "departmentSuggestions", field: "userId", isEqualTo: userId) { [weak self] (result: Result<[DepartmentSuggestionModel], AppError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let suggestions):
                    self?.suggestions = suggestions.sorted { $0.createdAt > $1.createdAt }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

