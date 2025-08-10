//
//  WeeklyErrorCard.swift
//  wodAI
//
//  Created by Jordan Littell on 8/10/25.
//

import SwiftUI

// MARK: - Error Card
struct WeeklyErrorCard: View {
    let message: String
    let onRetry: () -> Void
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(Color("Warning"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unable to load workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
                
                Button(action: onGenerate) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Generate New")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Warning").opacity(0.3), lineWidth: 1)
        )
    }
}
