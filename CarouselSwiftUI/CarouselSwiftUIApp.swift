//
//  CarouselSwiftUIApp.swift
//  CarouselSwiftUI
//
//  Created by Rashid Latif on 30/07/2024.
//

import SwiftUI

@main
struct CarouselSwiftUIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
