//
//  NavBar.swift
//  wodAI
//
//  Created by Jordan Littell on 4/26/25.
//

import SwiftUI

struct NavBar: View {
    @State var showProfile: Bool = false
    
    var body: some View {
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
    }
}

#Preview {
    NavBar()
}
