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

// MARK: - Frame Store

@MainActor
private class FrameStore: ObservableObject {
    @Published var frames: [UUID: CGRect] = [:]

    func update(id: UUID, frame: CGRect) {
        self.frames[id] = frame
    }
}

// MARK: - Report Subview Frame Modifier

private struct ReportFrameModifier: ViewModifier {
    let id: UUID = UUID()
    @ObservedObject var store: FrameStore

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            store.update(id: id, frame: proxy.frame(in: .global))
                        }
                }
            )
    }
}

private extension View {
    func reportFrame(store: FrameStore) -> some View {
        modifier(ReportFrameModifier(store: store))
    }
}

// MARK: - Inspector Modifier

private struct SwiftUIInspectorModifier: ViewModifier {
    @Environment(\.inspectionDisabled) private var isDisabled

    @State private var isInspecting = false
    @State private var showActions = false
    @State private var selectedID: UUID? = nil
    @StateObject private var frameStore = FrameStore()

    func body(content: Content) -> some View {
        content
            .reportFrame(store: frameStore)
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
            .overlay(
                Group {
                    if isInspecting {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .allowsHitTesting(false)

                            ForEach(frameStore.frames.keys.sorted(by: { $0.uuidString < $1.uuidString }), id: \.self) { id in
                                if let frame = frameStore.frames[id] {
                                    Rectangle()
                                        .stroke(selectedID == id ? Color.red : Color.blue, lineWidth: 2)
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

