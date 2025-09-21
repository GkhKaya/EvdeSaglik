//
//  DrugFoodInteractionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 21.09.2025.
//

import SwiftUI

struct DrugFoodInteractionView: View {
    @StateObject private var viewModel: DrugFoodInteractionViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(userManager: UserManager, firestoreManager: FirestoreManager, authManager: FirebaseAuthManager) {
        self._viewModel = StateObject(wrappedValue: DrugFoodInteractionViewModel(
            userManager: userManager,
            firestoreManager: firestoreManager,
            authManager: authManager
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ResponsivePadding.large) {
                    // Header
                    VStack(spacing: ResponsivePadding.medium) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text(NSLocalizedString("DrugFoodInteraction.Title", comment: "İlaç & Gıda Etkileşimi"))
                            .font(.title2Responsive)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(NSLocalizedString("DrugFoodInteraction.Description", comment: "İlaç ve gıda arasındaki etkileşimleri kontrol edin"))
                            .font(.subheadlineResponsive)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, ResponsivePadding.large)
                    
                    // Input Fields
                    VStack(spacing: ResponsivePadding.medium) {
                        CustomTextField(
                            title: NSLocalizedString("DrugFoodInteraction.DrugName", comment: "İlaç Adı"),
                            placeholder: NSLocalizedString("DrugFoodInteraction.DrugNamePlaceholder", comment: "İlaç adını girin"),
                            icon: "pills",
                            text: $viewModel.drugName,
                            isMultiline: false
                        )
                        
                        CustomTextField(
                            title: NSLocalizedString("DrugFoodInteraction.FoodName", comment: "Gıda Adı"),
                            placeholder: NSLocalizedString("DrugFoodInteraction.FoodNamePlaceholder", comment: "Gıda adını girin"),
                            icon: "fork.knife",
                            text: $viewModel.foodName,
                            isMultiline: false
                        )
                    }
                    
                    // Check Button - Moved to safeAreaInset below
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }
                    
                    // Interaction Result
                    if !viewModel.interactionResult.isEmpty {
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            Text(viewModel.interactionResult)
                                .font(.bodyResponsive)
                                .foregroundStyle(.primary)
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color(.systemGray).opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                            
                            // Save button
                            Button(action: {
                                viewModel.saveToHistory()
                            }) {
                                HStack {
                                    if viewModel.isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                    Text(NSLocalizedString("DrugFoodInteraction.Save", comment: "Kaydet"))
                                        .font(.bodyResponsive)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemGray6))
                                )
                                .foregroundStyle(.primary)
                            }
                            .disabled(viewModel.isSaving)
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    }
                    
                    // Reset Button
                    if !viewModel.drugName.isEmpty || !viewModel.foodName.isEmpty || !viewModel.interactionResult.isEmpty {
                        Button(action: {
                            viewModel.resetForm()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(NSLocalizedString("DrugFoodInteraction.Reset", comment: "Sıfırla"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ResponsivePadding.medium)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer(minLength: ResponsivePadding.extraLarge)
                }
                .padding(.horizontal, ResponsivePadding.large)
            }
            .navigationTitle(NSLocalizedString("DrugFoodInteraction.Title", comment: "İlaç & Gıda Etkileşimi"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(NSLocalizedString("DrugFoodInteraction.SaveSuccess", comment: "Başarılı"), isPresented: $viewModel.saveSuccess) {
                Button(NSLocalizedString("Common.OK", comment: "Tamam")) {
                    viewModel.saveSuccess = false
                }
            } message: {
                Text(NSLocalizedString("DrugFoodInteraction.SaveSuccessMessage", comment: "Etkileşim geçmişe kaydedildi"))
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    viewModel.checkInteraction()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(viewModel.isLoading ? 
                             NSLocalizedString("DrugFoodInteraction.Checking", comment: "Kontrol ediliyor...") : 
                             NSLocalizedString("DrugFoodInteraction.Check", comment: "Etkileşimi Kontrol Et"))
                            .font(.bodyResponsive)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(ResponsivePadding.medium)
                    .background(
                        Capsule()
                            .fill(viewModel.drugName.isEmpty || viewModel.foodName.isEmpty ? Color.gray : Color.blue)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.vertical, ResponsivePadding.medium)
                }
                .disabled(viewModel.isLoading || viewModel.drugName.isEmpty || viewModel.foodName.isEmpty)
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DrugFoodInteractionView(
        userManager: UserManager(),
        firestoreManager: FirestoreManager(),
        authManager: FirebaseAuthManager()
    )
}
