//
//  DomRenderer.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//

import Foundation
import JavaScriptKit


public class DomRenderer: Renderer {
    public typealias RefObject = JSObject
    public let root: any Element
    public var elementRefMap: [UUID: (parentId: UUID?, element: JSObject)] = [:]
    
    public var previousProps: [UUID: DictValue] = [:]
    
    public init(root: any Element) {
        self.root = root
        RendererContext.current = self
    }
    
    public func mount() {
        print("starting initialal mount")
        let document = JSObject.global.document
        let container = document.getElementById("app").object!
        let appId = UUID()
        print("done constructing parent \(appId)")
        elementRefMap[appId] = (parentId: nil, element: container)
        print("added parent to refMap \(elementRefMap)")
        mountElement(root, parentId: appId)
    }
    
    public func unmountElement(_ elementId: UUID) {
        let element = elementRefMap[elementId]
        guard let element else { return }
        let (_, node) = element
        _ = node.remove!()
        elementRefMap.removeValue(forKey: elementId)
        previousProps.removeValue(forKey: elementId)
    }
    
    struct PropsDiff {
        var added: [String: Any]
        var changed: [String: Any]
        var removed: [String]
    }
    
    func diffProps(old: DictValue, new: DictValue) -> PropsDiff {
        var added: [String: Any] = [:]
        var changed: [String: Any] = [:]
        var removed: [String] = []
        
        for key in new.keys {
            let newVal = new[key]!
            if let oldVal = old[key] {
                if !areValuesEqual(oldVal, newVal) {
                    changed[key] = newVal
                }
            } else {
                added[key] = newVal
            }
        }
        
        for key in old.keys {
            if new[key] == nil {
                removed.append(key)
            }
        }
        
        return PropsDiff(added: added, changed: changed, removed: removed)
    }
    
    func areValuesEqual(_ a: Any, _ b: Any) -> Bool {
        return String(describing: a) == String(describing: b)
    }
    
    
    public func updateElement(_ element: any Element, parentId: UUID?) {
        print("updateElement \(element.name) \(element.refId)")
        
        let elementRef = elementRefMap[element.refId]
        var node: JSObject
        var thisElementRef: (parentId: UUID?, element: JSObject)
        
        if let existing = elementRef {
            node = existing.element
            thisElementRef = (parentId: existing.parentId ?? parentId, element: node)
            print("updateElement reuse node \(element.name) \(element.refId)")
        } else {
            print("updateElement create node")
            node = JSObject.global.document.createElement(element.name).object!
            thisElementRef = (parentId: parentId, element: node)
        }
        
        elementRefMap[element.refId] = thisElementRef
        
        
        let oldProps = previousProps[element.refId] ?? DictValue()
        let newProps = element._attributes
        
        let diff = diffProps(old: oldProps, new: newProps)
        
        func applyProp(key: String, value: Any, on node: JSObject) {
            if let convertible = value as? ConvertibleToJSValue {
                node[key] = convertible.jsValue
                return
            }
            
            if let closure = newProps.function(key) {
                node[key] = JSClosure { _ in
                    closure()
                    return .undefined
                }.jsValue
                return
            }
            
            if let dict = newProps.dictionary(key) {
                let childNode = node[key].object!
                for (subKey, subVal) in dict {
                    applyProp(key: subKey, value: subVal, on: childNode)
                }
                return
            }
        }
        
        for key in diff.removed {
            node[key] = JSValue.undefined
        }
        
        for (key, val) in diff.added {
            applyProp(key: key, value: val, on: node)
        }
        
        for (key, val) in diff.changed {
            applyProp(key: key, value: val, on: node)
        }
        
        previousProps[element.refId] = newProps
        
        
        if elementRef == nil {
            let parent = elementRefMap[thisElementRef.parentId ?? UUID()]
            _ = parent?.element.appendChild!(node)
        }
        
        
        for child in element.children {
            mountElement(child, parentId: element.refId)
        }
    }
    
    
    public func mountElement(_ element: any Element, parentId: UUID) {
        updateElement(element, parentId: parentId)
    }
}
