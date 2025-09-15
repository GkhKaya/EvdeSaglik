//
//  CustomCheckbox.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct CustomCheckbox: View {
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: ResponsivePadding.small) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.bodyResponsive)
                    .foregroundStyle(isChecked ? .blue : .secondary)
                
                Text(title)
                    .font(.subheadlineResponsive)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        CustomCheckbox(title: "Beni hatırla", isChecked: .constant(true))
        CustomCheckbox(title: "Şartları kabul ediyorum", isChecked: .constant(false))
    }
    .padding()
}


