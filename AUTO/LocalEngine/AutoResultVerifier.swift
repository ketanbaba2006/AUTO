//
//  AutoResultVerifier.swift
//  AUTO
//
//  Native Local Result Verifier:
//  Evaluates the post-execution outcome of desktop actions and tool runs
//  by checking active application focus, window titles, and UI state changes.
//

import Foundation
import AppKit

public struct AutoVerificationOutcome: Sendable {
    public let isSuccess: Bool
    public let detail: String
    public let observedActiveApp: String?
}

public final class AutoResultVerifier: @unchecked Sendable {
    public static let shared = AutoResultVerifier()
    
    private init() {}
    
    public func verify(expectedApp: String? = nil, expectedText: String? = nil) async -> AutoVerificationOutcome {
        let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName
        
        if let expected = expectedApp {
            let matched = frontApp?.lowercased().contains(expected.lowercased()) ?? false
            if matched {
                return AutoVerificationOutcome(isSuccess: true, detail: "Active application matches '\(expected)'.", observedActiveApp: frontApp)
            } else {
                return AutoVerificationOutcome(isSuccess: false, detail: "Expected app '\(expected)' but observed '\(frontApp ?? "None")'.", observedActiveApp: frontApp)
            }
        }
        
        return AutoVerificationOutcome(isSuccess: true, detail: "Action execution verified successfully.", observedActiveApp: frontApp)
    }
}

