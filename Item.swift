//
//  Item.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//

import Foundation


struct Item: Codable, Identifiable, Hashable {
    var userId: Int
    var id: Int
    var title: String
    var body: String
}
