//
//  User.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import Foundation
import FirebaseAuth

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var displayName: String
    var profileImageURL: String?
    var createdAt: Date
    var filterUsageCount: Int
    var favoriteFilterIDs: [String]
    
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName ?? "User"
        self.profileImageURL = firebaseUser.photoURL?.absoluteString
        self.createdAt = Date()
        self.filterUsageCount = 0
        self.favoriteFilterIDs = []
    }
    
    init(id: String, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
        self.filterUsageCount = 0
        self.favoriteFilterIDs = []
    }
}

struct FilterUsageRecord: Identifiable, Codable {
    let id: String
    let userID: String
    let filterID: String
    let filterName: String
    let usedAt: Date
    var capturedMediaURL: String?
    
    init(userID: String, filterID: String, filterName: String) {
        self.id = UUID().uuidString
        self.userID = userID
        self.filterID = filterID
        self.filterName = filterName
        self.usedAt = Date()
    }
}
