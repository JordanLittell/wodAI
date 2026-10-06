//
//  HIITWorkoutCard.swift
//  wodAI
//
//  The WOD card: format header, a top-right accessory slot, and the
//  whiteboard-style display text. Shared by MetconView (bookmark accessory,
//  execution-state border) and the Assistant's session blocks.
//

import SwiftUI

struct HIITWorkoutCard<Accessory: View>: View {
    let format: String?
    let displayText: String
    var borderColor: Color = Color("Border")
    var borderWidth: CGFloat = 1
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if let format {
                    Text(format)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                }
                Spacer()
                accessory()
            }
            HStack(alignment: .top) {
                
            }

            Text(displayText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
}
