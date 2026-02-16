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
    var compact: Bool = false
    
    private var iconSize: CGFloat { compact ? 12 : 16 }
    private var iconWidth: CGFloat { compact ? 18 : 24 }
    private var valueWidth: CGFloat { compact ? 32 : 40 }
    private var valueFontSize: CGFloat { compact ? 11 : 14 }
    private var spacing: CGFloat { compact ? 6 : 12 }
    
    var body: some View {
        HStack(spacing: spacing) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(color)
                .frame(width: iconWidth)
            
            Slider(value: $value, in: range)
                .tint(color)
            
            Text(String(format: "%.1f", value))
                .font(.system(size: valueFontSize, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .frame(width: valueWidth, alignment: .trailing)
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
