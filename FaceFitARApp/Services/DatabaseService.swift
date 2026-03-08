//
//  DatabaseService.swift
//  FaceFitARApp
//
//  Created by Agastya Nand on 05/03/26.
//

import Foundation
import FirebaseFirestore
import CoreData

class DatabaseService {
    
    static let shared = DatabaseService()
    private let db = Firestore.firestore()
    
    // MARK: - Collection Paths
    private enum Collections {
        static let users = "users"
        static let filterUsage = "filter_usage"
    }
    
    private init() {}
    
    // MARK: - User Operations
    
    func saveUser(_ user: User) async throws {
        let data: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "displayName": user.displayName,
            "profileImageURL": user.profileImageURL as Any,
            "createdAt": Timestamp(date: user.createdAt),
            "filterUsageCount": user.filterUsageCount,
            "favoriteFilterIDs": user.favoriteFilterIDs
        ]
        
        try await db.collection(Collections.users)
            .document(user.id)
            .setData(data, merge: true)
    }
    
    func fetchUser(id: String) async throws -> User? {
        let snapshot = try await db.collection(Collections.users)
            .document(id)
            .getDocument()
        
        guard let data = snapshot.data() else { return nil }
        
        return User(
            id: data["id"] as? String ?? id,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? ""
        )
    }
    
    func updateUserFilterCount(userID: String) async throws {
        try await db.collection(Collections.users)
            .document(userID)
            .updateData([
                "filterUsageCount": FieldValue.increment(Int64(1))
            ])
    }
    
    func addFavoriteFilter(userID: String, filterID: String) async throws {
        try await db.collection(Collections.users)
            .document(userID)
            .updateData([
                "favoriteFilterIDs": FieldValue.arrayUnion([filterID])
            ])
    }
    
    // MARK: - Filter Usage Metadata
    
    func logFilterUsage(_ record: FilterUsageRecord) async throws {
        let data: [String: Any] = [
            "id": record.id,
            "userID": record.userID,
            "filterID": record.filterID,
            "filterName": record.filterName,
            "usedAt": Timestamp(date: record.usedAt),
            "capturedMediaURL": record.capturedMediaURL as Any
        ]
        
        try await db.collection(Collections.filterUsage)
            .document(record.id)
            .setData(data)
        
        // Update user count
        try await updateUserFilterCount(userID: record.userID)
    }
    
    func fetchFilterUsageHistory(userID: String, limit: Int = 20) async throws -> [FilterUsageRecord] {
        let snapshot = try await db.collection(Collections.filterUsage)
            .whereField("userID", isEqualTo: userID)
            .order(by: "usedAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> FilterUsageRecord? in
            let data = doc.data()
            guard
                let id = data["id"] as? String,
                let userID = data["userID"] as? String,
                let filterID = data["filterID"] as? String,
                let filterName = data["filterName"] as? String,
                let timestamp = data["usedAt"] as? Timestamp
            else { return nil }
            
            var record = FilterUsageRecord(
                userID: userID,
                filterID: filterID,
                filterName: filterName
            )
            return record
        }
    }
    
    func fetchMostUsedFilters(userID: String) async throws -> [String: Int] {
        let records = try await fetchFilterUsageHistory(userID: userID, limit: 100)
        return records.reduce(into: [:]) { counts, record in
            counts[record.filterName, default: 0] += 1
        }
    }
}

// MARK: - CoreData Stack (Local Persistence)
class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FaceFitAR")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
    
    // Background context for async writes
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}

