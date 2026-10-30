//
//  PermissionRow.swift
//  AUTO
//
//  Modular UI row displaying individual permission status and grant actions.
//

import SwiftUI

public struct PermissionRow: View {
    public let type: PermissionType
    public let isGranted: Bool
    public let onAction: () -> Void
    
    public init(type: PermissionType, isGranted: Bool, onAction: @escaping () -> Void) {
        self.type = type
        self.isGranted = isGranted
        self.onAction = onAction
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: type.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isGranted ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(type.requiredDescription)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            } else {
                Button(action: onAction) {
                    Text("Grant")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.cyan, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
