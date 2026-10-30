//
//  ConversationView.swift
//  AUTO
//
//  Displays conversational exchanges, transcription feedback, and step-by-step guidance.
//

import SwiftUI

public struct ConversationView: View {
    @ObservedObject public var appState: ApplicationState
    @ObservedObject public var conversationManager: ConversationManager
    @State private var inputText: String = ""
    
    public init(
        appState: ApplicationState,
        conversationManager: ConversationManager
    ) {
        self.appState = appState
        self.conversationManager = conversationManager
    }
    
    public init() {
        self.appState = .shared
        self.conversationManager = .shared
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if conversationManager.turns.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(conversationManager.turns) { turn in
                                turnView(turn)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 220)
            }
            
            // Manual test input bar
            HStack(spacing: 8) {
                TextField("Ask AUTO a question...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitInput()
                    }
                
                Button(action: submitInput) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .cyan)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            AUTOMascotView(
                state: appState.voiceState,
                powerLevel: appState.currentAudioLevel,
                size: 52,
                showGlow: true
            )
            .padding(.top, 12)
            
            Text("Hold ⌃ Control to Talk")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text("AUTO sees your screen and guides you step-by-step.")
                .font(.system(size: 11))
                .foregroundColor(BrandTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // Suggestion pills
            VStack(spacing: 6) {
                suggestionButton("What's on my screen right now?")
                suggestionButton("Help me find the right button to click")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(BrandTheme.Colors.surfaceNavy.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
    
    private func suggestionButton(_ prompt: String) -> some View {
        Button(action: {
            inputText = prompt
            submitInput()
        }) {
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                    .foregroundColor(BrandTheme.Colors.cyan)
                Text(prompt)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private func turnView(_ turn: ConversationTurn) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // User query
            HStack {
                Spacer()
                Text(turn.userTranscript)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Assistant response
            HStack(alignment: .top, spacing: 6) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 6, height: 6)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(turn.assistantResponse)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.95))
                    
                    if let point = turn.targetPoint {
                        HStack(spacing: 4) {
                            Image(systemName: "cursorarrow.rays")
                                .font(.system(size: 10))
                            Text("Target: \(point.label) (Screen \(point.screenIndex))")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.12), in: Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func submitInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        conversationManager.sendUserInput(text)
    }
}
