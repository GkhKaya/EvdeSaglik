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
    var isMultiline: Bool = false // Yeni eklenen isMultiline parametresi
    var onIconTap: (() -> Void)? = nil // Yeni eklenen onIconTap closure parametresi
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsivePadding.small) {
            if !title.isEmpty { // Sadece başlık varsa göster
                Text(title)
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.primary)
            }
            
            HStack(spacing: ResponsivePadding.small) {
                if !icon.isEmpty { // Sadece ikon varsa göster
                    if let onIconTap = onIconTap { // onIconTap sağlanmışsa, ikon bir düğme olur
                        Button(action: onIconTap) {
                            Image(systemName: icon)
                                .font(.bodyResponsive)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                        }
                    } else {
                        Image(systemName: icon)
                            .font(.bodyResponsive)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                    }
                }
                
                Group {
                    if isMultiline {
                        TextEditor(text: $text)
                            // Removed fixed frame. TextEditor will grow based on content.
                            .scrollDisabled(true) // Disable TextEditor's own scrolling to allow parent ScrollView to scroll
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                            .overlay(
                                Text(text.isEmpty ? placeholder : "")
                                    .foregroundStyle(Color(.placeholderText))
                                    .padding(.horizontal, 5) // TextEditor'ın iç boşluğu
                                    .allowsHitTesting(false) // Tıklanabilirliği kapat
                                , alignment: .topLeading
                            )
                            .padding(5) // TextEditor'ın kendi boşluğu
                    } else if isSecure && !isPasswordVisible {
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
            .padding(isMultiline ? 0 : ResponsivePadding.medium) // Multiline ise padding'i TextEditor'a bırak
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
        
        CustomTextField(
            title: "Çok Satırlı Mesaj",
            placeholder: "Buraya uzun bir mesaj yazın...",
            icon: "text.bubble",
            text: .constant("Bu çok satırlı bir metin alanı."),
            isMultiline: true
        )
    }
    .padding()
}


