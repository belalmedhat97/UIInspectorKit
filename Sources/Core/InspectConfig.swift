//
//  InspectConfig.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

public enum InspectEnvironment {
    case dev, qa, prod
}

public struct InspectConfig {
    @MainActor public static var environment: [InspectEnvironment] = [.prod]
}
