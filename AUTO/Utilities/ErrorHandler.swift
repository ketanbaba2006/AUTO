//
//  ErrorHandler.swift
//  AUTO
//
//  Unified error domain and structured error handling for AUTO.
//

import Foundation

public enum AUTOError: LocalizedError, CustomStringConvertible, Sendable, Equatable {
    case keychainError(status: Int32, message: String)
    case permissionDenied(permission: String, instructions: String)
    case aiProviderError(provider: String, message: String, statusCode: Int?)
    case authenticationFailed(provider: String, detail: String)
    case rateLimitExceeded(provider: String, retryAfter: TimeInterval?)
    case serverUnavailable(provider: String, statusCode: Int)
    case requestTimeout(provider: String)
    case cancelled
    case unsupportedModel(modelId: String)
    case emptyResponse
    case malformedJSON(detail: String)
    case streamingInterrupted(detail: String)
    case networkError(underlying: String)
    case audioCaptureError(reason: String)
    case speechRecognitionError(reason: String)
    case screenCaptureError(reason: String)
    case invalidConfiguration(detail: String)
    case modelNotFound(modelId: String)
    case parsingError(detail: String)
    case invalidOperation(String)
    case internalError(String)
    case automationError(reason: String)
    case unknown(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status, let message):
            return "Keychain error (\(status)): \(message)"
        case .permissionDenied(let permission, let instructions):
            return "Permission required: \(permission). \(instructions)"
        case .aiProviderError(let provider, let message, let statusCode):
            if let code = statusCode {
                return "AI provider '\(provider)' error (\(code)): \(message)"
            }
            return "AI provider '\(provider)' error: \(message)"
        case .authenticationFailed(let provider, let detail):
            return "Authentication failed for \(provider): \(detail)"
        case .rateLimitExceeded(let provider, let retryAfter):
            if let seconds = retryAfter {
                return "Rate limit exceeded for \(provider). Please wait \(Int(seconds))s before retrying."
            }
            return "Rate limit exceeded for \(provider). Please try again shortly."
        case .serverUnavailable(let provider, let statusCode):
            return "\(provider) server unavailable (HTTP \(statusCode))."
        case .requestTimeout(let provider):
            return "Request to \(provider) timed out."
        case .cancelled:
            return "Request was cancelled."
        case .unsupportedModel(let modelId):
            return "The selected model '\(modelId)' is not supported by this provider."
        case .emptyResponse:
            return "Received an empty response from the AI provider."
        case .malformedJSON(let detail):
            return "Failed to parse provider response: \(detail)"
        case .streamingInterrupted(let detail):
            return "Streaming response was interrupted: \(detail)"
        case .networkError(let underlying):
            return "Network connection error: \(underlying)"
        case .audioCaptureError(let reason):
            return "Audio capture failed: \(reason)"
        case .speechRecognitionError(let reason):
            return "Speech recognition failed: \(reason)"
        case .screenCaptureError(let reason):
            return "Screen capture failed: \(reason)"
        case .invalidConfiguration(let detail):
            return "Invalid configuration: \(detail)"
        case .modelNotFound(let modelId):
            return "AI model '\(modelId)' not found."
        case .parsingError(let detail):
            return "Data parsing error: \(detail)"
        case .invalidOperation(let reason):
            return "Invalid operation: \(reason)"
        case .internalError(let reason):
            return "Internal error: \(reason)"
        case .automationError(let reason):
            return "Automation error: \(reason)"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed(let provider, _):
            return "Verify your \(provider) API key in AUTO Settings > AI Providers."
        case .rateLimitExceeded:
            return "Wait a few seconds or check your provider API quota."
        case .serverUnavailable(let provider, _):
            if provider == "OmniRoute" {
                return "Ensure your local or remote OmniRoute server is running."
            }
            return "Check the provider's status page or try again in a few minutes."
        case .requestTimeout:
            return "Check your network connection and verify provider server responsiveness."
        case .permissionDenied(let permission, _):
            return "Open macOS System Settings > Privacy & Security to enable \(permission) for AUTO."
        case .aiProviderError:
            return "Please verify your API key or gateway URL in AUTO Settings > AI Providers."
        case .keychainError:
            return "Ensure your macOS Keychain is unlocked and accessible."
        case .networkError:
            return "Check your internet connection or verify the local gateway is running."
        case .screenCaptureError:
            return "Ensure Screen Recording permission is granted in macOS System Settings."
        case .audioCaptureError:
            return "Ensure Microphone permission is granted and a valid input device is connected."
        default:
            return nil
        }
    }
    
    public var description: String {
        return errorDescription ?? "Unknown AUTO Error"
    }
}
