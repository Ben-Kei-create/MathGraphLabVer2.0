//
//  IconButton.swift
//  MathGraph Lab
//
//  50x50 circular floating button with SF Symbols icon
//

import SwiftUI

struct IconButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                )
        }
    }
}

// Preview
#Preview {
    HStack(spacing: 16) {
        IconButton(icon: "slider.horizontal.3", color: .blue) {
            print("Settings tapped")
        }
        IconButton(icon: "pencil.and.outline", color: .orange) {
            print("Drawing tapped")
        }
        IconButton(icon: "arrow.counterclockwise", color: .gray) {
            print("Reset tapped")
        }
        IconButton(icon: "square.and.arrow.up", color: .green) {
            print("Export tapped")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
