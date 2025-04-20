//
//  HomeView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

struct SheetDetail {
    var strength: Int;
    var intensity: Int;
    var volume: Int;
    var skill: Int;
}

struct HomeView: View {
    
    @State var workout: Workout;
    @State var showWorkoutForm: Bool = false;
    
    @State var showProfile: Bool = false;
    
    @State var sheetDetail = SheetDetail(
        strength: 1,
        intensity: 2,
        volume:3,
        skill: 4);
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ZStack {
                        HStack {
                            Label("elite", systemImage: "flame")
                                .foregroundStyle(.red)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.gray)
                                .padding(.leading, 10)
                                .font(.footnote)
                        }
                    }
                    Spacer()
                    
                    Image(systemName: "person.crop.circle")
                    .font(.title)
                    .onTapGesture {
                        showProfile = true
                    }
                    .sheet(isPresented: $showProfile) {
                        ProfileView()
                    }
                        
                }
                .padding(.horizontal, 30)
                
                WorkoutView(workout: workout)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
            CircleButtonView(iconName: "plus")
                .offset(x: 150)
                .offset(y: 350)
                .onTapGesture {
                    showWorkoutForm = true
                }
                .sheet(isPresented: $showWorkoutForm, content: {
                    VStack(alignment: .leading, spacing: 20) {
                        WorkoutGenerationForm(loadParams: WorkoutFixture.loadParams)
                    }
                })
            }
        }
    
    func didDismiss() {
        showWorkoutForm = false
    }
    
}

#Preview {
    VStack {
        HomeView(workout: WorkoutFixture.workout)
    }
}
