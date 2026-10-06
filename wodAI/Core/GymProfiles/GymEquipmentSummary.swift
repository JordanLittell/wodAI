//
//  GymEquipmentSummary.swift
//  wodAI

import SwiftUI

struct GymEquipmentSummary: View {
    @StateObject private var profileManager = GymProfileManager.shared

    var body: some View {
        if let activeProfile = profileManager.activeProfile {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(Color("BrandPrimary"))

                    Text("Equipment at \(activeProfile.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))

                    Spacer()

                    Text("\(activeProfile.equipment.count) types")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activeProfile.equipment.sorted(by: { $0.name < $1.name })) { equipment in
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

struct CompactGymEquipmentSummary: View {
    @StateObject private var profileManager = GymProfileManager.shared

    var body: some View {
        if let activeProfile = profileManager.activeProfile {
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .font(.caption)
                    .foregroundColor(Color("BrandPrimary"))

                Text(activeProfile.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))

                Text("•")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))

                Text("\(activeProfile.equipment.count) equipment")
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
