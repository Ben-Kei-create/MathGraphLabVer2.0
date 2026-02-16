//
//  IconSegmentedControl.swift
//  MathGraph Lab
//
//  Icon-based segmented control for visual selection
//

import SwiftUI

struct IconSegmentedControl<T: Hashable>: View {
    
    struct Option {
        let value: T
        let icon: String
        let label: String?
        
        init(value: T, icon: String, label: String? = nil) {
            self.value = value
            self.icon = icon
            self.label = label
        }
    }
    
    let options: [Option]
    @Binding var selection: T
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selection = option.value
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: option.icon)
                            .font(.system(size: 18, weight: .semibold))
                        if let label = option.label {
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundColor(selection == option.value ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selection == option.value ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// Preview
#Preview {
    VStack(spacing: 30) {
        // Theme selector
        IconSegmentedControl(
            options: [
                .init(value: "light", icon: "sun.max.fill", label: nil),
                .init(value: "dark", icon: "moon.fill", label: nil),
                .init(value: "blackboard", icon: "chalkboard.fill", label: nil)
            ],
            selection: .constant("light")
        )
        .frame(width:   180)
        
        // Input mode selector
        IconSegmentedControl(
            options: [
                .init(value: "decimal", icon: "0.circle.fill", label: "0.4"),
                .init(value: "fraction", icon: "1.circle.fill", label: "0.4")
            ],
            selection: .constant("decimal")
        )
        .frame(width: 180)
    }
    .padding()
}
