//
//  InspectConfig.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

public enum InspectEnvironment {
    case dev, qa, prod
}

@MainActor
public struct InspectConfig {
    /// Current environment (default: prod)
    public private(set) static var environment: InspectEnvironment = .prod

    /// Helper used throughout the inspectors
    public static var isEnvironmentEnabled: Bool {
        switch environment {
        case .dev, .qa: return true
        case .prod: return false
        }
    }

    /// Configure the environment
    public static func setupEnvironment(_ env: InspectEnvironment) {
        environment = env
    }
}
