//
//  ParameterSliderWithIcon.swift
//  MathGraph Lab
//
//  Slider with icon and numeric value, no text labels
//

import SwiftUI

struct ParameterSliderWithIcon: View {
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon on the left
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            
            // Slider in the center
            Slider(value: $value, in: range)
                .tint(color)
            
            // Numeric value on the right
            Text(String(format: "%.1f", value))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        Text("パラメータスライダー（アイコンのみ）")
            .font(.headline)
        
        VStack(spacing: 16) {
            ParameterSliderWithIcon(
                icon: "arrow.up.and.down",
                value: .constant(1.0),
                range: -5...5,
                color: .blue
            )
            
            ParameterSliderWithIcon(
                icon: "arrow.left.and.right",
                value: .constant(0.0),
                range: -5...5,
                color: .blue
            )
            
            ParameterSliderWithIcon(
                icon: "line.diagonal",
                value: .constant(1.0),
                range: -5...5,
                color: .red
            )
            
            ParameterSliderWithIcon(
                icon: "arrow.up.and.down.circle",
                value: .constant(2.0),
                range: -10...10,
                color: .red
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
    .padding()
}
