//
//  ItemViewModel.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//

import Foundation

@Observable
class ItemViewModel {
    var items: [Item] = []
    var isLoading = false
    
    
    func fetchItems() async {
        
        isLoading = true
        print("Inside IttemViewModel")
        defer {
            isLoading = false
        }
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            items = try JSONDecoder().decode([Item].self, from: data)
            
           // print("Items \(items)")
            
        }catch {
            print(error.localizedDescription)
        }
                
        
    }
}
