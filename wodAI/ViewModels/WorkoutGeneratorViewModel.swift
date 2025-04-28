//
//  WorkoutGeneratorViewModel.swift
//  wodAI
//
//  Created by Jordan Littell on 4/26/25.
//

import Foundation
import WodAiAPI


class WorkoutGeneratorViewModel : ObservableObject {
    @Published var generating: Bool;
    @Published var workout: Workout;

    init(generating: Bool, workout: Workout) {
        self.generating = generating
        self.workout = workout
    }
    
    func generate(workoutDescription: String) {
        let input = CreateWodInput(description: GraphQLNullable(stringLiteral: workoutDescription))
        self.generating = true;
        
        Network.shared.client.perform(mutation: GenerateWODMutation(input: input))  { result in
            switch result {
            case .success(let graphqlResult):
                guard
                    let definition = graphqlResult.data?.generateWod.definition,
                    let format = graphqlResult.data?.generateWod.format,
                    let id = graphqlResult.data?.generateWod.id else { return }
                
                self.workout = Workout(definition: definition,
                                  stimulus: "",
                                  muscles: "",
                                  format: format,
                                  id: id)
                self.generating = false
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func update(description: String) {
        Network.shared.client.perform(mutation: UpdateWodMutation(
            updateWodId: workout.id,
            input: UpdateWodInput(id: GraphQLNullable(stringLiteral: workout.id),
                                  instructions: GraphQLNullable(stringLiteral: description)))) { resp in
            switch resp {
            case .success(let successResp):
                guard
                    let definition = successResp.data?.updateWod.definition,
                    let format = successResp.data?.updateWod.format,
                    let id = successResp.data?.updateWod.id else { return }
                self.workout = Workout(definition: definition,
                                  stimulus: "",
                                  muscles: "",
                                  format: format,
                                  id: id)
                self.generating = false
            case .failure(let error):
                print("error \(error.localizedDescription)")
            }
        }
    }
}
