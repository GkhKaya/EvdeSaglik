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
                    VStack(spacing: ResponsivePadding.small) {
                        Text(NSLocalizedString("DrugFoodInteraction.Title", comment: "İlaç & Gıda Etkileşim Kontrolü"))
                            .font(.largeTitleResponsive)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(NSLocalizedString("DrugFoodInteraction.Subtitle", comment: "İlaç ve gıda etkileşimlerini kontrol edin, olası yan etkileri öğrenin."))
                            .font(.bodyResponsive)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.top, ResponsivePadding.medium)
                    
                    // Input Fields
                    VStack(spacing: ResponsivePadding.medium) {
                        CustomTextField(
                            title: NSLocalizedString("DrugFoodInteraction.DrugName.Label", comment: "İlaç Adı"),
                            placeholder: NSLocalizedString("DrugFoodInteraction.DrugName.Placeholder", comment: "örn: Aspirin, Paracetamol"),
                            icon: "pills",
                            text: $viewModel.drugName
                        )
                        
                        CustomTextField(
                            title: NSLocalizedString("DrugFoodInteraction.FoodName.Label", comment: "Gıda Adı"),
                            placeholder: NSLocalizedString("DrugFoodInteraction.FoodName.Placeholder", comment: "örn: Greyfurt, Süt, Kahve"),
                            icon: "fork.knife",
                            text: $viewModel.foodName
                        )
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage.localizedDescription)
                            .font(.bodyResponsive)
                            .foregroundColor(.red)
                            .padding(.horizontal, ResponsivePadding.large)
                            .padding(.vertical, ResponsivePadding.small)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(ResponsiveRadius.medium)
                            .padding(.horizontal, ResponsivePadding.large)
                    }
                    
                    Spacer(minLength: ResponsivePadding.large)
                    
                    // Results
                    if !viewModel.interactionResult.isEmpty {
                        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                            Text("Etkileşim Analizi")
                                .font(.title2Responsive)
                                .fontWeight(.bold)
                            
                            Text(viewModel.interactionResult)
                                .font(.bodyResponsive)
                                .padding(ResponsivePadding.medium)
                                .background(Color(.systemGray6))
                                .cornerRadius(ResponsiveRadius.medium)
                            
                            // Save Button
                            Button(action: {
                                viewModel.saveToHistory()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                    Text(NSLocalizedString("DrugFoodInteraction.Save", comment: "Geçmişe Kaydet"))
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
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    }
                    
                    Spacer(minLength: ResponsivePadding.extraLarge)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    viewModel.checkInteraction()
                }) {
                    HStack {
                        if viewModel.isLoading { 
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(NSLocalizedString("DrugFoodInteraction.Submit", comment: "Etkileşimi Kontrol Et"))
                            .font(.bodyResponsive)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(ResponsivePadding.medium)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.vertical, ResponsivePadding.medium)
                }
                .disabled(viewModel.isLoading || viewModel.drugName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2Responsive)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .alert(NSLocalizedString("DrugFoodInteraction.SaveSuccess", comment: "Başarıyla kaydedildi"), isPresented: $viewModel.saveSuccess) {
            Button("Tamam") {
                viewModel.resetForm()
            }
        }
    }
}

struct DrugFoodInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        DrugFoodInteractionView(
            userManager: UserManager(),
            firestoreManager: FirestoreManager(),
            authManager: FirebaseAuthManager()
        )
    }
}
