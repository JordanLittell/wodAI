//
//  WeeklyLoadingCard.swift
//  wodAI
//
//  Created by Jordan Littell on 8/10/25.
//
import SwiftUI

// MARK: - Loading Card
struct WeeklyLoadingCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Surface2"))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 150, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 100, height: 12)
                }
                
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Surface2"))
                .frame(height: 60)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .redacted(reason: .placeholder)
    }
}
