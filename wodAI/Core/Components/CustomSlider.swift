//
//  CustomSlider.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let thumbColor: Color
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbPosition = normalizedValue * sliderWidth
            
            ZStack(alignment: .leading) {
                // Track Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(trackColor)
                    .frame(height: 8)
                
                // Active Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(thumbColor)
                    .frame(width: thumbPosition, height: 8)
                
                // Thumb
                Circle()
                    .fill(thumbColor)
                    .frame(width: isDragging ? 28 : 24, height: isDragging ? 28 : 24)
                    .shadow(color: .black.opacity(0.2), radius: isDragging ? 4 : 2)
                    .position(x: thumbPosition, y: geometry.size.height / 2)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let newValue = (gesture.location.x / sliderWidth) * (range.upperBound - range.lowerBound) + range.lowerBound
                        let steppedValue = round(newValue / step) * step
                        value = min(max(steppedValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 32)
    }
}
