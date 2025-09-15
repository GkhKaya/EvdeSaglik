//
//  LifestyleSelectionView.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct LifestyleSelectionView: View {
    let title: String
    let description: String
    let options: [LifestyleOption]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            // Title and Description
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                Text(title)
                    .font(.subheadlineResponsive)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption1Responsive)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Options
            VStack(spacing: ResponsivePadding.small) {
                ForEach(options, id: \.title) { option in
                    LifestyleOptionCard(
                        option: option,
                        isSelected: selectedOption == option.title,
                        action: { selectedOption = option.title }
                    )
                }
            }
        }
    }
}

struct LifestyleOption {
    let title: String
    let description: String
    let example: String
}

struct LifestyleOptionCard: View {
    let option: LifestyleOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: ResponsivePadding.small) {
                HStack {
                    Text(option.title)
                        .font(.subheadlineResponsive)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .blue : .primary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                
                Text(option.description)
                    .font(.caption1Responsive)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(option.example)
                    .font(.caption2Responsive)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ResponsivePadding.medium)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .strokeBorder(
                        isSelected ? Color.blue : Color(.separator),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var selectedSleep = ""
    
    let sleepOptions = [
        LifestyleOption(
            title: "İyi",
            description: "Düzenli uyku saatleri ve kaliteli uyku",
            example: "Örnek: Günde 7-9 saat uyuyorum, gece 23:00'da yatıp sabah 07:00'de kalkıyorum"
        ),
        LifestyleOption(
            title: "Orta",
            description: "Bazen düzensizlik yaşanıyor",
            example: "Örnek: Günde 5-7 saat uyuyorum, uyku saatlerim değişken"
        ),
        LifestyleOption(
            title: "Kötü",
            description: "Düzensiz uyku ve yetersiz dinlenme",
            example: "Örnek: Günde 5 saatten az uyuyorum, sürekli uykusuzum"
        )
    ]
    
    return LifestyleSelectionView(
        title: "Uyku Düzeni",
        description: "Genel uyku kalitenizi ve düzeninizi değerlendirin",
        options: sleepOptions,
        selectedOption: $selectedSleep
    )
    .padding()
}

