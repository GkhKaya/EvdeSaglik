//
//  LabResultRecommendationView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct LabResultRecommendationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = LabResultRecommendationViewViewModel()
    @State private var showingDocumentPicker = false
    @State private var selectedPDFDocument: PDFDocument?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                    // Header
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        Text(NSLocalizedString("LabResult.Title", comment: ""))
                            .font(.title1Responsive)
                            .fontWeight(.bold)
                        Text(NSLocalizedString("LabResult.Subtitle", comment: ""))
                            .font(.subheadlineResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    .padding(.top, ResponsivePadding.medium)
                    
                    // Warning
                    VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(NSLocalizedString("LabResult.Warning", comment: ""))
                                .font(.headlineResponsive)
                                .fontWeight(.semibold)
                        }
                        Text(NSLocalizedString("LabResult.WarningText", comment: ""))
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                    }
                    .padding(ResponsivePadding.medium)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    // PDF Upload Section
                    VStack(spacing: ResponsivePadding.medium) {
                        Button(action: { showingDocumentPicker = true }) {
                            VStack(spacing: ResponsivePadding.small) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.blue)
                                Text(NSLocalizedString("LabResult.UploadPDF", comment: ""))
                                    .font(.headlineResponsive)
                                    .fontWeight(.semibold)
                                Text(NSLocalizedString("LabResult.UploadDescription", comment: ""))
                                    .font(.captionResponsive)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ResponsivePadding.large)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                    .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .background(Color.blue.opacity(0.05))
                            )
                        }
                        .disabled(viewModel.isLoading)
                        
                        if let pdfDoc = selectedPDFDocument {
                            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundStyle(.green)
                                    Text(NSLocalizedString("LabResult.PDFSelected", comment: ""))
                                        .font(.bodyResponsive)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(pdfDoc.pageCount) \(NSLocalizedString("LabResult.Pages", comment: ""))")
                                        .font(.captionResponsive)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if !viewModel.extractedTables.isEmpty {
                                    Text(NSLocalizedString("LabResult.TablesExtracted", comment: ""))
                                        .font(.captionResponsive)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(ResponsivePadding.medium)
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, ResponsivePadding.large)
                    
                    // Analysis Results
                    if viewModel.isLoading {
                        HStack { 
                            ProgressView()
                            Text(NSLocalizedString("Common.Loading", comment: ""))
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding(.horizontal, ResponsivePadding.large)
                    } else if !viewModel.abnormalItems.isEmpty {
                        // Abnormal items pretty rendering
                        VStack(alignment: .leading, spacing: ResponsivePadding.medium) {
                            ForEach(viewModel.abnormalItems) { item in
                                VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                                    // Test name
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "cross.case.fill")
                                            .foregroundStyle(.red)
                                        Text(item.test)
                                            .font(.headlineResponsive)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.bottom, ResponsivePadding.xSmall)

                                    // Quick facts row
                                    HStack(spacing: ResponsivePadding.small) {
                                        Label("\(NSLocalizedString("LabResult.Label.Value", comment: "")): \(item.value)", systemImage: "number")
                                            .font(.captionResponsive)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                                        Label("\(NSLocalizedString("LabResult.Label.Unit", comment: "")): \(item.unit)", systemImage: "scalemass")
                                            .font(.captionResponsive)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.teal.opacity(0.1)))
                                        Label("\(NSLocalizedString("LabResult.Label.Reference", comment: "")): \(item.referenceRange)", systemImage: "scope")
                                            .font(.captionResponsive)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.orange.opacity(0.1)))
                                    }

                                    Divider()

                                    // Remedy
                                    VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "leaf.fill").foregroundStyle(.green)
                                            Text(NSLocalizedString("LabResult.Label.Remedy", comment: ""))
                                                .font(.subheadlineResponsive)
                                                .fontWeight(.semibold)
                                        }
                                        Text(item.remedy)
                                            .font(.bodyResponsive)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    // Doctor advice
                                    VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "stethoscope").foregroundStyle(.purple)
                                            Text(NSLocalizedString("LabResult.Label.Doctor", comment: ""))
                                                .font(.subheadlineResponsive)
                                                .fontWeight(.semibold)
                                        }
                                        Text(item.doctorAdvice)
                                            .font(.bodyResponsive)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color(.systemGray).opacity(0.08), radius: 8, x: 0, y: 4)
                                )
                            }

                            // Save button
                            Button(action: saveToHistory) {
                                HStack {
                                    if viewModel.isSaving { ProgressView().scaleEffect(0.8) }
                                    Image(systemName: "square.and.arrow.down")
                                    Text(NSLocalizedString("LabResult.Save", comment: ""))
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

                            if let saveMsg = viewModel.saveMessage {
                                Text(saveMsg)
                                    .font(.captionResponsive)
                                    .foregroundStyle(saveMsg.contains("başarı") ? .green : .red)
                                    .padding(.top, ResponsivePadding.small)
                            }
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    } else if !viewModel.sections.isEmpty {
                        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                            ForEach(viewModel.sections) { section in
                                VStack(alignment: .leading, spacing: ResponsivePadding.xSmall) {
                                    if !section.title.isEmpty {
                                        Text(section.title)
                                            .font(.headlineResponsive)
                                            .fontWeight(.semibold)
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(section.lines, id: \.self) { item in
                                            HStack(alignment: .top, spacing: 8) {
                                                Circle()
                                                    .fill(Color.accentColor)
                                                    .frame(width: 6, height: 6)
                                                    .padding(.top, 6)
                                                Text(item)
                                                    .font(.bodyResponsive)
                                                    .foregroundStyle(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                }
                                .padding(ResponsivePadding.medium)
                                .background(
                                    RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color(.systemGray).opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                            }
                            
                            // Save button
                            Button(action: saveToHistory) {
                                HStack {
                                    if viewModel.isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                    }
                                    Text(NSLocalizedString("LabResult.Save", comment: ""))
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
                            
                            if let saveMsg = viewModel.saveMessage {
                                Text(saveMsg)
                                    .font(.captionResponsive)
                                    .foregroundStyle(saveMsg.contains("başarı") ? .green : .red)
                                    .padding(.top, ResponsivePadding.small)
                            }
                        }
                        .padding(.horizontal, ResponsivePadding.large)
                    }
                    
                    Spacer(minLength: ResponsivePadding.large)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedPDFDocument != nil {
                    Button(action: extractAndAnalyze) {
                        HStack {
                            if viewModel.isLoading { ProgressView() }
                            Text(viewModel.extractedTables.isEmpty ? 
                                 NSLocalizedString("LabResult.Analyze", comment: "") : 
                                 NSLocalizedString("LabResult.Reanalyze", comment: ""))
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
                    .disabled(viewModel.isLoading)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodyResponsive)
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    if let pdfDoc = PDFDocument(url: url) {
                        // Reset prior state
                        viewModel.extractedTables = []
                        viewModel.sections = []
                        viewModel.analysisResult = ""
                        selectedPDFDocument = pdfDoc
                    } else {
                        viewModel.showError(NSLocalizedString("Deepseek.Error.InvalidResponse", comment: ""))
                    }
                }
            }
        }
    }
    
    private func extractAndAnalyze() {
        guard let pdfDoc = selectedPDFDocument else { return }
        
        viewModel.setLoading(true)
        Task {
            let tables = await viewModel.extractTablesFromPDF(pdfDoc)
            await MainActor.run {
                viewModel.extractedTables = tables
            }
            
            let summary = userManager.generateUserSummaryPrompt()
            await viewModel.analyzeLabResults(userSummary: summary, tables: tables)
        }
    }
    
    private func saveToHistory() {
        if let userId = userManager.authManager?.currentUser?.uid {
            Task { viewModel.saveLabResults(userId: userId, firestoreManager: userManager.firestoreManager) }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

#Preview {
    LabResultRecommendationView()
}
