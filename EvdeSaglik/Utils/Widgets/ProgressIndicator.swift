//
//  ProgressIndicator.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 15.09.2025.
//

import SwiftUI

struct ProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: ResponsivePadding.small) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step < currentStep ? Color.blue : Color(.systemFill))
                    .frame(width: 10, height: 10)
                    .scaleEffect(step == currentStep - 1 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack {
        ProgressIndicator(totalSteps: 5, currentStep: 1)
        ProgressIndicator(totalSteps: 5, currentStep: 3)
        ProgressIndicator(totalSteps: 5, currentStep: 5)
    }
    .padding()
}

