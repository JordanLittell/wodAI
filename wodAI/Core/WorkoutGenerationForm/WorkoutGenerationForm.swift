//
//  WorkoutGenerationForm.swift
//  wodAI
//
//  Created by Jordan Littell on 4/19/25.
//

import SwiftUI
import WodAiAPI

struct WorkoutGenerationForm: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var loadParams: LoadParams;
   
    
    var body: some View {
        VStack {
            Text("Generate a new workout")
                .font(.title)
                .padding(.bottom, 10)
            
            
//            VStack {
//                Text("Strength")
//                HStack {
//                    Slider(
//                        value: Float($loadParams.weight?),
//                        in: 0...10,
//                        step: 1
//                    ) { editing in
//                        
//                    }
//                }
//                Text("\(Int(loadParams.strength))")
//            }
//            .padding(.horizontal, 10)
//            .padding(.bottom, 40)
//            
//            
//            VStack {
//                Text("Intensity")
//                HStack {
//                    
//                    Slider(
//                        value: $loadParams.intensity,
//                        in: 0...10,
//                        step: 1
//                    ) { editing in
//                        
//                    }
//                }
//                Text("\(Int(loadParams.intensity))")
//            }
//            .padding(.horizontal, 10)
//            .padding(.bottom, 40)
//            
//            
//            VStack {
//                Text("Skill")
//                HStack {
//                    Slider(
//                        value: $loadParams.skill,
//                        in: 0...10,
//                        step: 1
//                    ) { editing in
//                        
//                    }
//                }
//                Text("\(Int(loadParams.skill))")
//            }
//            .padding(.horizontal, 10)
//            .padding(.bottom, 40)
//            
//            VStack {
//                Text("Volume")
//                HStack {
//                    Slider(
//                        value: $loadParams.volume,
//                        in: 0...10,
//                        step: 1
//                    ) { editing in
//                        
//                    }
//                }
//                Text("\(Int(loadParams.volume))")
//            }
//            .padding(.horizontal, 10)
//            .padding(.bottom, 40)
            
            Button("Generate") {
                print("submit")
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: 350)
            .padding(.vertical, 20)
            .background(.black, in: .rect(cornerSize: CGSize(width: 10, height: 10)), fillStyle: .init())
            
        }
        
    }
    
    func getPercentValue(value: Int) -> Float {
        return Float(value)/10
    }
}

//#Preview {
//    WorkoutGenerationForm(loadParams:/* LoadParams(intensity: 1.0, strength: 2.0, skill: 3.0, volume: 5.0))*/
//}
