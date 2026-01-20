//
//  ItemCard.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//

import Foundation
import SwiftUI


struct ItemCard: View {
    let item: Item
   // @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationLink(value: item){
        VStack(alignment: .leading, spacing: 8){
            
            Text(item.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(item.body)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
        .onAppear(){
            print("Item \(item)")
        }
    }
}
