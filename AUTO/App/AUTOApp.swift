//
//  AUTOApp.swift
//  AUTO
//
//  Main application entry point for AUTO.
//

import SwiftUI
import AppKit

@main
public struct AUTOApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) public var appDelegate
    
    public init() {
        if CommandLine.arguments.contains("--test") || CommandLine.arguments.contains("--run-tests") {
            Task {
                await AUTOTestSuite.runAllTests()
                exit(0)
            }
        }
    }
    
    public var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

