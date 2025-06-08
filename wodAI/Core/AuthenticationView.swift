//
//  AuthenticationView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/7/25.
//
import SwiftUI

struct AuthenticationView: View {
    @State private var showingLogin = true
    
    var body: some View {
        NavigationStack {
            if showingLogin {
                LoginView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Sign Up") {
                                withAnimation(.easeInOut) {
                                    showingLogin = false
                                }
                            }
                        }
                    }
            } else {
                SignUpView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign In") {
                                withAnimation(.easeInOut) {
                                    showingLogin = true
                                }
                            }
                        }
                    }
            }
        }
    }
}
