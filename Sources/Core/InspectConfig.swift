//
//  InspectConfig.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

enum InspectEnvironment {
    case dev, qa, prod
}

struct InspectConfig {
    @MainActor static var environment: [InspectEnvironment] = [.prod]
}
