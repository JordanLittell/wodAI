//
//  TimerView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/19/25.
//

import SwiftUI

struct TimerView: View {
    @State var isPaused: Bool = false
    
    @Binding var progress: Double
    @Binding var duration: TimeInterval
    
    var body: some View {
        HStack {
            CircleButtonView(iconName: "chevron.left")
            Spacer()
        }
        Spacer()
        
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.08)
                .foregroundColor(.black)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(270.0))
                .foregroundColor(.black)
                .frame(width: 200, height: 200)
            
            Text(duration.format(using: [.minute, .second]))
                .font(.title2.bold())
                .foregroundColor(.black)
                .contentTransition(.numericText())
        }
        
        Spacer()
        controls
    }
    
    var controls: some View {
        HStack {
            CircleButtonView(iconName: "arrow.2.circlepath")
                .foregroundStyle(.white)
                
            Spacer()
            if isPaused {
                CircleButtonView(iconName: "play")
                    .foregroundStyle(.white)
                    .onTapGesture {
    
                    }
            } else {
                CircleButtonView(iconName: "pause")
                    .foregroundStyle(.white)
                    .onTapGesture {
    
                    }
            }
            
                
            Spacer()
            CircleButtonView(iconName: "checkmark")
                .foregroundStyle(.green)
                
                
        }.frame(maxWidth: 300)
    }
}

extension TimeInterval {
    func format(using units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? ""
    }
}

#Preview {
    TimerView(progress: .constant(0.4), duration: .constant(100))
}
