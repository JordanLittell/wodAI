//
//  WorkoutView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI
import WodAiAPI

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
            .frame(height: UIScreen.main.bounds.height * (0.60))
            .onAppear() {
                let input = CreateWodInput(
                    description: "Generate a chipper workout that uses dummbells, gymnastics, and lunges");
                Network.shared.client.perform(mutation: GenerateWODMutation(input: input))  { result in
                    switch result {
                    case .success(let graphqlResult):
                        guard
                            let definition = graphqlResult.data?.generateWod.definition,
                            let name = graphqlResult.data?.generateWod.name,
                            let id = graphqlResult.data?.generateWod.id else { return }
                        workout = Workout(definition: definition, stimulus: "", muscles: "", title: name, id: id)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                }
                
            }
            
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
