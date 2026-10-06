//
//  CircleButtonView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//
import SwiftUI

struct CircleButtonView: View {
    let iconName: String;
    var body: some View {
        Image(systemName: iconName)
            .font(.title)
            .foregroundColor(Color.white)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .foregroundColor(.black)
                
            )
            .shadow(radius: 10, x: 0, y: 0)
            .padding()
    }
}

#Preview {
    VStack {
        CircleButtonView(iconName: "dumbbell.fill")
        CircleButtonView(iconName: "bolt.heart.fill")
            .colorScheme(.dark)
    }
}
