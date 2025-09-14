//
//  CustomTextField.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            Text(title)
                .font(.subheadlineResponsive)
                .foregroundStyle(.primary)
            
            HStack(spacing: ResponsivePadding.small) {
                Image(systemName: icon)
                    .font(.bodyResponsive)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.bodyResponsive)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                
                if showPasswordToggle {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(ResponsivePadding.medium)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveRadius.medium)
                    .strokeBorder(Color(.separator), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
        }
    }
}

#Preview {
    VStack {
        CustomTextField(
            title: "E-posta",
            placeholder: "ornek@email.com",
            icon: "envelope",
            text: .constant("")
        )
        
        CustomTextField(
            title: "Şifre",
            placeholder: "Şifreniz",
            icon: "lock",
            text: .constant(""),
            isSecure: true,
            showPasswordToggle: true
        )
    }
    .padding()
}
