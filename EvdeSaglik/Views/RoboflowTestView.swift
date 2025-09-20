import SwiftUI
import PhotosUI

struct RoboflowTestView: View {
    @State private var isLoading: Bool = false
    @State private var predictions: [SkinDiseasePrediction] = []
    @State private var errorMessage: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotosPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Cilt Hastalığı Tespiti")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Görselinizi yükleyin ve AI ile analiz edin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Image Selection Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Görsel Seçin:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                showingPhotosPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Galeri")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Kamera")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        if let selectedImage = selectedImage {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Seçilen Görsel:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Analyze Button
                    Button(action: {
                        analyzeImage()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isLoading ? "Analiz Ediliyor..." : "Görseli Analiz Et")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedImage != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || selectedImage == nil)
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Predictions
                    if !predictions.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Tahmin Sonuçları")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(predictions.enumerated()), id: \.offset) { index, prediction in
                                PredictionCard(prediction: prediction, rank: index + 1)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    
                    // Reset Button
                    if selectedImage != nil || !predictions.isEmpty {
                        Button(action: {
                            resetView()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Sıfırla")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingPhotosPicker) {
                PhotosPicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func analyzeImage() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        errorMessage = ""
        predictions = []
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Görsel veriye dönüştürülemedi"
            isLoading = false
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Make API call to local skin disease detection API
        guard let url = URL(string: "http://localhost:5002/predict") else {
            errorMessage = "API URL'si geçersiz"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "image": base64String
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "İstek oluşturulamadı: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.handleResponse(data: data, response: response, error: error)
            }
        }.resume()
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
        isLoading = false
        
        if let error = error {
            errorMessage = "Ağ hatası: \(error.localizedDescription)"
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Geçersiz yanıt"
            return
        }
        
        guard httpResponse.statusCode == 200 else {
            errorMessage = "HTTP Hatası: \(httpResponse.statusCode)"
            return
        }
        
        guard let data = data else {
            errorMessage = "Veri alınamadı"
            return
        }
        
        do {
            let response = try JSONDecoder().decode(SkinDiseaseResponse.self, from: data)
            self.predictions = response.predictions
        } catch {
            errorMessage = "Yanıt çözümlenemedi: \(error.localizedDescription)"
        }
    }
    
    private func resetView() {
        selectedImage = nil
        predictions = []
        errorMessage = ""
        isLoading = false
    }
}

// MARK: - Prediction Card
struct PredictionCard: View {
    let prediction: SkinDiseasePrediction
    let rank: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 30, height: 30)
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.disease_tr)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(prediction.disease_en)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(prediction.confidence))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rankColor)
                            .frame(width: geometry.size.width * CGFloat(prediction.confidence/100.0), height: 6)
                    }
                }
                .frame(width: 60, height: 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return .orange
        case 3: return .blue
        default: return .gray
        }
    }
}

// MARK: - Data Models
struct SkinDiseaseResponse: Codable {
    let predictions: [SkinDiseasePrediction]
}

struct SkinDiseasePrediction: Codable {
    let disease_en: String
    let disease_tr: String
    let confidence: Double
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PhotosPicker
struct PhotosPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotosPicker
        
        init(_ parent: PhotosPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct RoboflowTestView_Previews: PreviewProvider {
    static var previews: some View {
        RoboflowTestView()
    }
}