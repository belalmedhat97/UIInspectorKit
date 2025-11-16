//
//  Untitled.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

import SwiftUI
import Core

private struct InspectionEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var inspectionDisabled: Bool {
        get { self[InspectionEnvironmentKey.self] }
        set { self[InspectionEnvironmentKey.self] = newValue }
    }
}

struct SwiftUIInspectorModifier: ViewModifier {
    @Environment(\.inspectionDisabled) private var isDisabled
    @State private var isInspecting = false
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        ZStack {
            content
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            frame = proxy.frame(in: .global)
                        }
                    }
                )
                .onLongPressGesture {
                    guard InspectConfig.isEnvironmentEnabled, !isDisabled else { return }
                    withAnimation { isInspecting.toggle() }
                }

            if isInspecting {
                Color.black.opacity(0.3)
                    .cornerRadius(12)
                    .onTapGesture {
                        withAnimation { isInspecting = false }
                    }

                VStack {
                    Spacer().frame(height: frame.height + 8)
                    Button("Share View Info") {
                        share()
                        isInspecting = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .transition(.scale)
            }
        }
    }

    private func share() {
        let info = """
        🔍 SwiftUI View Inspection:
        Frame: \(frame)
        Size: \(frame.size.width) x \(frame.size.height)
        Environment: \(InspectConfig.environment)
        """
        let activityVC = UIActivityViewController(activityItems: [info], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

public struct AutoInspectionModifier: ViewModifier {
    public func body(content: Content) -> some View {
        if InspectConfig.isEnvironmentEnabled {
            return AnyView(
                content
                    .modifier(SwiftUIInspectorModifier())
            )
        } else {
            return AnyView(content)
        }
    }
}

public extension View {

    /// Apply inspection automatically for entire app
    func autoInspectionEnabled() -> some View {
        modifier(AutoInspectionModifier())
    }

    /// Disable inspection for this specific view
    func disableInspection() -> some View {
        environment(\.inspectionDisabled, true)
    }
}
