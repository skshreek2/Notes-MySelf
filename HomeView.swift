//
//  TabsView.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 19/01/26.
//

import Foundation
import SwiftUICore
import SwiftUI


struct HomeView: View {
    
    @State private var path = NavigationPath()
    @State private var itemvieModel = ItemViewModel()
    @State private var selectedItem: Item?
    
    var body: some View {
                NavigationStack(path: $path) {
                        ScrollView {
                            if itemvieModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight:  .infinity)
                            } else {
//                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),GridItem(.flexible(), spacing: 12)], spacing: 12){
//                                    ForEach(itemvieModel.items){ item in
//                                        NavigationLink(value: item) {
//                                            ItemCard(item: item)
//                                        }
//                                    }
//                                }
//                                .padding()
        
                                List(itemvieModel.items) { item in
                                       NavigationLink(value: item) {
                                           ItemCard(item: item)
                                       }
                                   }
                                .listStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowSpacing(12)
                                .frame(maxHeight: .infinity)
                                .listRowBackground(Color.clear)
                            }
                    }
                    .navigationBarTitle("Dashboard")
                    .navigationDestination(for: Item.self){ item in
        
                        ItemDetailsView(item: item)
        
                    }
                    .task {
                        await itemvieModel.fetchItems()
                    }
                }
    }
}

struct ProfileView: View {
    var body: some View {
        VStack{
            Image(systemName: "person.fill")
                .font(.system(size: 80))
            Text("Profile Tab")
                .font(.largeTitle)
                .padding()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        VStack{
            Image(systemName: "gearshape.fill")
                .font(.system(size: 80))
            Text("Settings Tab")
                .font(.largeTitle)
                .padding()
        }
    }
}
