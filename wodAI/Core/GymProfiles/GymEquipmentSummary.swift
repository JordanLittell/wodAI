//
//  GymEquipmentSummary.swift
//  wodAI
//
//  Created by Claude on 6/9/25.
//

import SwiftUI

struct GymEquipmentSummary: View {
    @StateObject private var profileManager = GymProfileManager.shared
    
    var body: some View {
        if let selectedProfile = profileManager.selectedProfile {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: selectedProfile.icon)
                        .foregroundColor(Color("BrandPrimary"))
                    
                    Text("Equipment at \(selectedProfile.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Spacer()
                    
                    Text("\(selectedProfile.equipment.count) types")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                // Equipment names preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedProfile.equipment).sorted(by: { $0.name < $1.name })) { equipment in
                            Text(equipment.name)
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("Surface2"))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
    }
}

// Compact version for small spaces
struct CompactGymEquipmentSummary: View {
    @StateObject private var profileManager = GymProfileManager.shared
    
    var body: some View {
        if let selectedProfile = profileManager.selectedProfile {
            HStack(spacing: 8) {
                Image(systemName: selectedProfile.icon)
                    .font(.caption)
                    .foregroundColor(Color("BrandPrimary"))
                
                Text(selectedProfile.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
                
                Text("\(selectedProfile.equipment.count) equipment")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("BrandPrimary").opacity(0.08))
            .cornerRadius(6)
        }
    }
}

// Preview
struct GymEquipmentSummary_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GymEquipmentSummary()
            CompactGymEquipmentSummary()
        }
        .padding()
        .background(Color("Background"))
    }
}
