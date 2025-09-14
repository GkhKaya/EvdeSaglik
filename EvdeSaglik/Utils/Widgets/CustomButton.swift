//
//  CustomButton.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                }
                Text(title)
                    .font(.bodyResponsive)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(ResponsivePadding.medium)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .fill(backgroundColor)
            )
            .foregroundStyle(textColor)
        }
        .disabled(!isEnabled || isLoading)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? Color.blue : Color(.systemFill)
        case .secondary:
            return Color(.secondarySystemBackground)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .white : .secondary
        case .secondary:
            return .primary
        }
    }
}

#Preview {
    VStack {
        CustomButton(
            title: "Giriş Yap",
            action: { },
            isEnabled: true
        )
        
        CustomButton(
            title: "Hesap Oluştur",
            action: { },
            style: .secondary
        )
        
        CustomButton(
            title: "Yükleniyor...",
            action: { },
            isLoading: true
        )
    }
    .padding()
}
