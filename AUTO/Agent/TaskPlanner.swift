//
//  TaskPlanner.swift
//  AUTO
//
//  Converts high-level user instructions into structured, executable multi-step plans.
//  Determines tool requirements, step dependencies, risk classifications, and verification criteria.
//

import Foundation

public final class TaskPlanner: @unchecked Sendable {
    public static let shared = TaskPlanner()
    
    public init() {}
    
    /// Generates a structured multi-step plan for a user request.
    public func planTask(instruction: String) -> AgentTaskPlan {
        let cleaned = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()
        
        // 1. File Organization Workflow
        if lower.contains("organize") && (lower.contains("desktop") || lower.contains("folder") || lower.contains("file")) {
            return planFileOrganization(instruction: cleaned)
        }
        
        // 2. Browser Search & Summarization Workflow
        if (lower.contains("search") || lower.contains("look up")) && (lower.contains("safari") || lower.contains("web") || lower.contains("chrome")) {
            return planWebSearch(instruction: cleaned)
        }
        
        // 3. Screen Inspection & Explanation Workflow
        if lower.contains("what") && (lower.contains("screen") || lower.contains("error") || lower.contains("looking at")) {
            return planScreenInspection(instruction: cleaned)
        }
        
        // 4. User Preference Memory Storage Workflow
        if lower.contains("remember") || lower.contains("preference") {
            return planMemoryStorage(instruction: cleaned)
        }
        
        // 5. Default General Assistance Plan
        return planGeneralTask(instruction: cleaned)
    }
    
    // MARK: - Workflow Template Planners
    
    private func planFileOrganization(instruction: String) -> AgentTaskPlan {
        let step1 = AgentTaskStep(
            stepNumber: 1,
            title: "Inspect Desktop Directory",
            explanation: "List eligible files on the Desktop to identify items needing organization.",
            requiredTool: "files.list",
            parameters: ["path": "~/Desktop"],
            riskLevel: .low,
            verificationMethod: "Verify file listing returned items."
        )
        let step2 = AgentTaskStep(
            stepNumber: 2,
            title: "Propose File Organization Plan",
            explanation: "Categorize files by extension (documents, images, archives) and confirm destination folders.",
            requiredTool: "conversation.send_message",
            parameters: ["message": "I found files to organize. Awaiting your approval before moving items."],
            dependencies: [step1.id],
            riskLevel: .low
        )
        let step3 = AgentTaskStep(
            stepNumber: 3,
            title: "Move Files to Destination Folders",
            explanation: "Safely relocate authorized files to designated category folders.",
            requiredTool: "files.organize",
            dependencies: [step2.id],
            riskLevel: .high,
            verificationMethod: "Verify file exists in destination folder."
        )
        let step4 = AgentTaskStep(
            stepNumber: 4,
            title: "Report Organization Summary",
            explanation: "Provide a concise summary of all files moved.",
            requiredTool: "conversation.send_message",
            dependencies: [step3.id],
            riskLevel: .low
        )
        
        return AgentTaskPlan(
            originalInstruction: instruction,
            intendedOutcome: "Organize Desktop files into tidy categorized folders.",
            steps: [step1, step2, step3, step4],
            riskLevel: .high
        )
    }
    
    private func planWebSearch(instruction: String) -> AgentTaskPlan {
        let step1 = AgentTaskStep(
            stepNumber: 1,
            title: "Activate Web Browser",
            explanation: "Bring Safari to the foreground to execute search.",
            requiredTool: "app.activate",
            parameters: ["appName": "Safari"],
            riskLevel: .medium,
            verificationMethod: "Check Safari is frontmost application."
        )
        let step2 = AgentTaskStep(
            stepNumber: 2,
            title: "Inspect Search Controls",
            explanation: "Query accessible elements in Safari to locate the address/search bar.",
            requiredTool: "screen.inspect_elements",
            dependencies: [step1.id],
            riskLevel: .low
        )
        let step3 = AgentTaskStep(
            stepNumber: 3,
            title: "Execute Search Query",
            explanation: "Enter query into Safari and navigate to search results.",
            requiredTool: "automation.type_text",
            parameters: ["text": extractSearchTerms(from: instruction)],
            dependencies: [step2.id],
            riskLevel: .medium
        )
        let step4 = AgentTaskStep(
            stepNumber: 4,
            title: "Capture and Summarize Results",
            explanation: "Capture screen context to extract and synthesize the best results.",
            requiredTool: "screen.capture",
            dependencies: [step3.id],
            riskLevel: .low
        )
        
        return AgentTaskPlan(
            originalInstruction: instruction,
            intendedOutcome: "Search the web and provide a synthesized summary.",
            steps: [step1, step2, step3, step4],
            riskLevel: .medium
        )
    }
    
    private func planScreenInspection(instruction: String) -> AgentTaskPlan {
        let step1 = AgentTaskStep(
            stepNumber: 1,
            title: "Capture Active Screen Context",
            explanation: "Obtain a high-resolution snapshot of the user's active display.",
            requiredTool: "screen.capture",
            riskLevel: .low
        )
        let step2 = AgentTaskStep(
            stepNumber: 2,
            title: "Analyze Visual Hierarchy",
            explanation: "Inspect accessible elements in the frontmost window.",
            requiredTool: "screen.inspect_elements",
            dependencies: [step1.id],
            riskLevel: .low
        )
        let step3 = AgentTaskStep(
            stepNumber: 3,
            title: "Explain Screen Content",
            explanation: "Synthesize visual findings and answer the user's question.",
            requiredTool: "conversation.send_message",
            dependencies: [step2.id],
            riskLevel: .low
        )
        
        return AgentTaskPlan(
            originalInstruction: instruction,
            intendedOutcome: "Analyze screen content and explain visible information.",
            steps: [step1, step2, step3],
            riskLevel: .low
        )
    }
    
    private func planMemoryStorage(instruction: String) -> AgentTaskPlan {
        let step1 = AgentTaskStep(
            stepNumber: 1,
            title: "Store User Preference",
            explanation: "Save the requested preference or memory in local storage.",
            requiredTool: "memory.store",
            parameters: [
                "category": "userPreferences",
                "key": "user_preference",
                "content": instruction
            ],
            riskLevel: .low
        )
        let step2 = AgentTaskStep(
            stepNumber: 2,
            title: "Confirm Preference Saved",
            explanation: "Confirm to the user that AUTO has recorded the preference.",
            requiredTool: "conversation.send_message",
            parameters: ["message": "I will remember that preference for future tasks."],
            dependencies: [step1.id],
            riskLevel: .low
        )
        
        return AgentTaskPlan(
            originalInstruction: instruction,
            intendedOutcome: "Record user preference into local persistent memory.",
            steps: [step1, step2],
            riskLevel: .low
        )
    }
    
    private func planGeneralTask(instruction: String) -> AgentTaskPlan {
        let step1 = AgentTaskStep(
            stepNumber: 1,
            title: "Gather Context",
            explanation: "Identify active application and frontmost window state.",
            requiredTool: "app.get_frontmost",
            riskLevel: .low
        )
        let step2 = AgentTaskStep(
            stepNumber: 2,
            title: "Execute Response",
            explanation: "Respond to the user instruction with synthesized guidance.",
            requiredTool: "conversation.send_message",
            parameters: ["message": "Processing your request: \(instruction)"],
            dependencies: [step1.id],
            riskLevel: .low
        )
        
        return AgentTaskPlan(
            originalInstruction: instruction,
            intendedOutcome: "Fulfill request: \(instruction)",
            steps: [step1, step2],
            riskLevel: .low
        )
    }
    
    private func extractSearchTerms(from text: String) -> String {
        let phrases = ["search for ", "look up ", "search ", "find "]
        for p in phrases {
            if let range = text.range(of: p, options: .caseInsensitive) {
                return String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }
}

