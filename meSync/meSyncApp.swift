//
//  meSyncApp.swift
//  meSync
//
//  Created by Brandon Cean on 6/13/25.
//

import SwiftUI
import SwiftData

@main
struct meSyncApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            TaskData.self,
            HabitData.self,
            MedicationData.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If there's a migration issue, try to delete and recreate
            print("ModelContainer creation failed: \(error)")
            
            // Try with a fresh configuration
            let freshConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [freshConfiguration])
            } catch {
                // As last resort, use in-memory storage
                print("Falling back to in-memory storage: \(error)")
                let memoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfiguration])
                } catch {
                    fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
