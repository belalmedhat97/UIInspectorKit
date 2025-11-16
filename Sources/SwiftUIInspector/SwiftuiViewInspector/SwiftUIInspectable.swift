//
//  Untitled.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

import SwiftUI
import Core
// MARK: - Environment Key

private struct InspectionEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var inspectionDisabled: Bool {
        get { self[InspectionEnvironmentKey.self] }
        set { self[InspectionEnvironmentKey.self] = newValue }
    }
}

// MARK: - Preference Key for Subview Frames

private struct InspectableFrameKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect],
                       nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Modifier for Subviews to Report Frames

private struct ReportFrameModifier: ViewModifier {
    let id = UUID()

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: InspectableFrameKey.self,
                        value: [id: proxy.frame(in: .global)]
                    )
                }
            )
    }
}

private extension View {
    func reportFrame() -> some View {
        modifier(ReportFrameModifier())
    }
}

// MARK: - Inspector Overlay Modifier

private struct SwiftUIInspectorModifier: ViewModifier {
    @Environment(\.inspectionDisabled) private var isDisabled

    @State private var isInspecting = false
    @State private var showActions = false
    @State private var selectedID: UUID? = nil
    @State private var frames: [UUID: CGRect] = [:]

    func body(content: Content) -> some View {
        content
            .reportFrame() // every subview reports its frame
            .onLongPressGesture {
                guard InspectConfig.isEnvironmentEnabled, !isDisabled else { return }
                showActions = true
            }
            .confirmationDialog("Inspector", isPresented: $showActions, titleVisibility: .visible) {
                Button("Inspect") {
                    withAnimation { isInspecting.toggle() }
                }

                Button("Cancel", role: .cancel) {}
            }
            .background(
                GeometryReader { _ in
                    Color.clear.preference(key: InspectableFrameKey.self,
                                           value: frames)
                }
            )
            .onPreferenceChange(InspectableFrameKey.self) { value in
                frames = value
            }
            .overlay(
                Group {
                    if isInspecting {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture { isInspecting = false }

                            ForEach(frames.keys.sorted(by: { $0.uuidString < $1.uuidString }), id: \.self) { id in
                                if let frame = frames[id] {
                                    Rectangle()
                                        .stroke(selectedID == id ? Color.red : Color.blue,
                                                lineWidth: 2)
                                        .frame(width: frame.width, height: frame.height)
                                        .position(x: frame.midX, y: frame.midY)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedID = id
                                            share(frame: frame)
                                        }
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
            )
    }

    private func share(frame: CGRect) {
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

// MARK: - Auto Inspection Modifier

public struct AutoInspectionModifier: ViewModifier {
    public func body(content: Content) -> some View {
        if InspectConfig.isEnvironmentEnabled {
            return AnyView(
                content.modifier(SwiftUIInspectorModifier())
            )
        } else {
            return AnyView(content)
        }
    }
}

// MARK: - Public Extensions

public extension View {

    /// Enable automatic inspection for entire app
    func autoInspectionEnabled() -> some View {
        modifier(AutoInspectionModifier())
    }

    /// Disable inspection on a specific view
    func disableInspection() -> some View {
        environment(\.inspectionDisabled, true)
    }

    /// Enable inspection on individual sub-elements
    func inspectable() -> some View {
        modifier(SwiftUIInspectorModifier())
    }
}


