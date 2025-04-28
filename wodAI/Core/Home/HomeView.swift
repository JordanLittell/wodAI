//
//  HomeView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI
import WodAiAPI

struct SheetDetail {
    var strength: Int;
    var intensity: Int;
    var volume: Int;
    var skill: Int;
}

struct HomeView: View {
    @EnvironmentObject var wgvm: WorkoutGeneratorViewModel
    
    @State var showWorkoutForm: Bool = false;
    @State var showProfile: Bool = false;
    @State var selectedTab: Int = 0;
    
    @State var sheetDetail = SheetDetail(
        strength: 1,
        intensity: 2,
        volume:3,
        skill: 4);
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                WorkoutView()
                    .environmentObject(wgvm)
                    .tag(0)
                
                ProfileView()
                    .tag(1)
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            selectedTab = 1
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            showWorkoutForm = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .offset(y: -5)
                        
                        // Workout Button
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Image(systemName: "dumbbell.fill")
                                .font(.title2)
                                .foregroundColor(selectedTab == 0 ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .background(Color(.systemBackground))
                    .shadow(radius: 2)
                }
            )
        }
        .sheet(isPresented: $showWorkoutForm, content: {
            WorkoutGenerationForm(wgvm: wgvm)
        })
    }
    
    func didDismiss() {
        showWorkoutForm = false
    }
}

#Preview {
    VStack {
        HomeView()
            .environmentObject(WorkoutGeneratorViewModel(generating: false, workout: WorkoutFixture.workout))
    }
}
