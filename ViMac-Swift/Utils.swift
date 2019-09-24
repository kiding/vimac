//
//  Utils.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa
import AXSwift
import MASShortcut

class Utils: NSObject {
    static let defaultCommandShortcut = MASShortcut.init(keyCode: kVK_Space, modifierFlags: [.command, .shift])
    static let commandShortcutKey = "CommandShortcut"
    
    // This function returns the position of the point after the y-axis is flipped.
    // We need this because accessing the position of a AXUIElement gives us the position from top-left,
    // but the coordinate system in macOS starts from bottom-left.
    // https://developer.apple.com/documentation/applicationservices/kaxpositionattribute?language=objc
    static func toOrigin(point: CGPoint, size: CGSize) -> CGPoint {
        // cannot use NSScreen.main because the height of the global coordinate system can be larger
        // see: https://stackoverflow.com/a/45289010/10390454
        let screenHeight = NSScreen.screens.map { $0.frame.origin.y + $0.frame.height }.max()!
        return CGPoint(x: point.x, y: screenHeight - size.height - point.y)
    }
    
    static func moveMouse(position: CGPoint) {
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: position, mouseButton: .left)
        moveEvent?.post(tap: .cgSessionEventTap)
    }
    
    static func leftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        event?.post(tap: .cgSessionEventTap)
        event2?.post(tap: .cgSessionEventTap)
    }
    
    static func doubleLeftClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        event?.post(tap: .cgSessionEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cgSessionEventTap)
        
        event?.setIntegerValueField(.mouseEventClickState, value: 2)
        
        event?.type = .leftMouseDown
        event?.post(tap: .cgSessionEventTap)
        event?.type = .leftMouseUp
        event?.post(tap: .cgSessionEventTap)
    }
    
    static func rightClickMouse(position: CGPoint) {
        let event = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: position, mouseButton: .right)
        let event2 = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: position, mouseButton: .right)
        event?.post(tap: .cgSessionEventTap)
        event2?.post(tap: .cgSessionEventTap)
    }
    
    static func traverseUIElementForPressables(rootElement: UIElement) -> [UIElement]? {
        let windowFrameOptional: NSRect? = {
            do {
                return try rootElement.attribute(.frame)
            } catch {
                return nil
            }
        }()
        
        guard let windowFrame = windowFrameOptional else {
            return nil
        }
        
        var elements = [UIElement]()
        func fn(element: UIElement, level: Int) -> Void {
            let roleOptional: Role? = {
                do {
                    return try element.role()
                } catch {
                    return nil
                }
            }()
            
            let positionOptional: NSPoint? = {
                do {
                    return try element.attribute(.position)
                } catch {
                    return nil
                }
            }()
            
            // ignore subcomponents of a scrollbar
            if let role = roleOptional {
                if role == .scrollBar {
                    return
                }
            }
            
            if let position = positionOptional {
                if (windowFrame.contains(position)) {
                    elements.append(element)
                }
            }
            
            let children: [AXUIElement] = {
                do {
                    let childrenOptional = try element.attribute(Attribute.children) as [AXUIElement]?;
                    guard let children = childrenOptional else {
                        return []
                    }
                    return children
                } catch {
                    return []
                }
            }()
            
            children.forEach { child in
                fn(element: UIElement(child), level: level + 1)
            }
        }
        fn(element: rootElement, level: 1)
        return elements
    }
}
