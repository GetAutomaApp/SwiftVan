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
        guard let element else {return}
        let (_, node) = element
        _ = node.remove!()
        elementRefMap.removeValue(forKey: elementId)
    }
    
    public func updateElement(_ element: any Element, parentId: UUID?) {
        print("updateElement \(element.name) \(element.refId)")
        let elementRef = elementRefMap[element.refId]
        
        print("updateElement exists?")
        if elementRef != nil {
            print("updateElement exists = true")
        }
        
        var node: JSObject
        var thisElementRef: (parentId: UUID?, element: JSObject)
        
        if let existing = elementRef {
            node = existing.element
            thisElementRef = (parentId: existing.parentId ?? parentId, element: node)
            print("updateElement reuse node \(element.name) \(element.refId)")
            
            let resetKeys = ["onclick", "onchange", "oninput", "onmouseover", "onmouseout", "style"]
            for key in resetKeys {
                node[key] = JSValue.undefined
            }
            if let style = node["style"].object {
                style["cssText"] = ""
            }
        } else {
            print("updateElement create node")
            node = JSObject.global.document.createElement(element.name).object!
            thisElementRef = (parentId: parentId, element: node)
            print("updateElement updateRefMap 1 \(elementRefMap)")
        }
        
        elementRefMap[element.refId] = thisElementRef
        print("updateElement updateRefMap 2 \(elementRefMap)")
        
        // sets the initial text
        // we need to have some global context to which we assign the DomRenderer
        // dom renderer will have the courtesy to update elements
        // aka Text will call domrenderer that it has been updated with its id
        // dom renderer will then use the new state of text element to update text
        // unmounting from the Element protocl will also call unmount on dom renderer with the element id, it should destroy that element along with all its children
        // in this case we delete the parent first, meaning we can't call removeChild from js for all of them
        // which is fine, we try that, if no element we just remove it from the element map
        // TODO - Fix Rendering Styles Please
        // 05/10/2025 - TODO: We need to take all this code and the code in updateElement, make it be one
        // 05/10/2025 - TODO: We can iterate over the different types we support in the dict and add them
        // 05/10/2025 - TODO: Elements aren't convenient to use now, fix that by
        
        func vals(input: DictValue, node: JSObject) {
            for (key, value) in input {
                print("\(key)=\(value) \(value is DictValue)")
                if let value = value as? ConvertibleToJSValue {
                    print("key is val \(key)")
                    node[key] = value.jsValue
                }
                
                if let value = input.function(key) {
                    print("key is func \(key)")
                    node[key] = JSClosure { _ in
                        value()
                        return .undefined
                    }.jsValue
                }
                
                if let value = input.dictionary(key) {
                    print("key is dict \(key)")
                    vals(input: value, node: node[key].object!)
                }
            }
        }
        
        vals(input: element._attributes, node: node)
        
        let parent = elementRefMap[thisElementRef.parentId ?? UUID()]
        print(
            "pinning self to parent element \(element.name), parent=\(parent?.element) \(element.refId)"
        )
        
        if elementRef == nil {
            _ = parent?.element.appendChild!(node)
        }
        
        for child in element.children {
            mountElement(child, parentId: element.refId)
        }
    }

    
    public func mountElement(_ element: any Element, parentId: UUID) {
        print("call to mountElement \(element) \(parentId)")
        updateElement(element, parentId: parentId)
        print("call done mountElement \(element) \(parentId)")
    }
}
