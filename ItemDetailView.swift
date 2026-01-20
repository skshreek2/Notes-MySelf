//
//  ItemDetailsView.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//

import Foundation
import SwiftUI
import SwiftUICore



struct ItemDetailsView: View {
    
    //let itemId: Int
    let item: Item
    
 
    var body: some View {
        ScrollView {
            
            
            VStack(alignment: .leading, spacing:16 ) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Divider()
                
                Text("User Id \(item.userId)")
                    .font(.headline)
                Text("Item Id \(item.id)")
                    .font(.subheadline)
                Text("Body:")
                    .font(.headline)
                    .padding(.top)
                Text(item.body)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
                
            }
            .padding()
            
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
