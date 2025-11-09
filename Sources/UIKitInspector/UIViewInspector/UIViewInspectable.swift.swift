//
//  Untitled.swift
//  UIInspectorKit
//
//  Created by belal medhat on 06/11/2025.
//

import UIKit
import Core
import ObjectiveC

@MainActor private var inspectionDisabledKey: UInt8 = 0

public extension UIView {
    
    // MARK: - Selective Disable
    var isInspectionDisabled: Bool {
        get { objc_getAssociatedObject(self, &inspectionDisabledKey) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &inspectionDisabledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Swizzle for automatic inspection
    static let swizzleDidMoveToWindow: Void = {
        let originalSelector = #selector(UIView.didMoveToWindow)
        let swizzledSelector = #selector(UIView.swizzled_didMoveToWindow)

        guard let originalMethod = class_getInstanceMethod(UIView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc private func swizzled_didMoveToWindow() {
        self.swizzled_didMoveToWindow() // call original
        guard InspectConfig.environment.contains(where: { $0 != .prod }), !isInspectionDisabled else { return }

        if gestureRecognizers?.contains(where: { $0 is UILongPressGestureRecognizer }) == false {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleInspectLongPress(_:)))
            self.addGestureRecognizer(longPress)
            self.isUserInteractionEnabled = true
        }
    }

    // MARK: - Long Press Handler
    @objc private func handleInspectLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        showInspectionOverlay()
    }

    // MARK: - Overlay + Button
    private func showInspectionOverlay() {
        guard let parent = self.superview else { return }

        // Shadow overlay
        let overlay = UIView(frame: self.frame)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.layer.cornerRadius = self.layer.cornerRadius
        overlay.clipsToBounds = true
        overlay.tag = 9999
        overlay.alpha = 0

        // Share button
        let button = UIButton(type: .system)
        button.setTitle("Share View Info", for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.tag = 10000
        button.frame = CGRect(
            x: overlay.frame.origin.x,
            y: overlay.frame.maxY + 8,
            width: overlay.frame.width,
            height: 44
        )
        button.alpha = 0
        button.addTarget(self, action: #selector(shareViewInfo), for: .touchUpInside)

        // Tap outside to dismiss
        let tapDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay))
        parent.addGestureRecognizer(tapDismiss)
        tapDismiss.cancelsTouchesInView = false

        parent.addSubview(overlay)
        parent.addSubview(button)

        UIView.animate(withDuration: 0.25) {
            overlay.alpha = 1.0
            button.alpha = 1.0
        }
    }

    @objc private func dismissOverlay(_ gesture: UITapGestureRecognizer? = nil) {
        guard let parent = self.superview else { return }
        parent.viewWithTag(9999)?.removeFromSuperview()
        parent.viewWithTag(10000)?.removeFromSuperview()
    }

    @objc private func shareViewInfo() {
        var textColor: String = "N/A"
        
        // Detect UILabel text color if available
        if let label = self as? UILabel {
            textColor = label.textColor.description
        } else if let button = self as? UIButton {
            textColor = button.titleColor(for: .normal)?.description ?? "N/A"
        }
        
        let cornerRadius = self.layer.cornerRadius
        let shadowOpacity = self.layer.shadowOpacity
        let shadowRadius = self.layer.shadowRadius
        let shadowOffset = self.layer.shadowOffset
        
        let info = """
        🔍 UIView Inspection:
        Class: \(type(of: self))
        Frame: \(frame)
        Background: \(backgroundColor?.description ?? "nil")
        Alpha: \(alpha)
        Corner Radius: \(cornerRadius)
        Shadow: opacity=\(shadowOpacity), radius=\(shadowRadius), offset=\(shadowOffset.width),\(shadowOffset.height)
        Text Color: \(textColor)
        Tag: \(tag)
        """
        
        let vc = UIActivityViewController(activityItems: [info], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
        dismissOverlay()
    }

}

