//
//  EvdeSaglikApp.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 13.09.2025.
//

import SwiftUI
import FirebaseCore
@main

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


struct EvdeSaglikApp: App {
    
    @StateObject var firestoreManager = FirestoreManager()
    @StateObject var authManager = FirebaseAuthManager()
    
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
