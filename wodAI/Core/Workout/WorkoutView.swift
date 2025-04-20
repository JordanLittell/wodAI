//
//  WorkoutView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

struct WorkoutView: View {
    
    @State var workout: Workout;
    @State var showTimer: Bool = false;
    @State var isPaused: Bool = false;
    @State var restartRequested: Bool = false;
    
    var body: some View {
        
        if showTimer {
            TimerView(progress: .constant(50.0), duration: .constant(15.0))
        } else {
            VStack {
                HStack {
                    Text("\(workout.title)")
                        .fontWeight(.bold)
                        .font(.headline)
                        .padding(.bottom, 10)
                }
                .padding(.bottom, 10)
                
                Text("\(workout.definition)")
                    .font(.subheadline)
            }
            .frame(height: UIScreen.main.bounds.height * (0.60) )
            
            Text("Start")
                .foregroundStyle(.green)
                
            Text("Mark Completed")
                .foregroundStyle(.blue)

        }
    }
    
}

#Preview {
    WorkoutView(workout: WorkoutFixture.workout)
}
