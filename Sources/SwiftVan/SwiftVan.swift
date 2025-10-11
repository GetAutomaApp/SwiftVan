//
//  SwiftVan.swift
//  SwiftVan4
//
//  Created by Simon Ferns on 9/29/25.
//

import JavaScriptKit
import Foundation

public enum RendererContext {
    nonisolated(unsafe) public static var current: (any Renderer)?
    nonisolated(unsafe) public static var currentBuildingElement: Element?
}

@resultBuilder
public struct ArrayBuilder<T> {
    public static func buildBlock() -> [T] { [] }
    public static func buildBlock(_ components: [T]...) -> [T] { components.flatMap { $0 } }
    
    public static func buildExpression(_ expression: T) -> [T] { [expression] }
    public static func buildExpression(_ expression: T?) -> [T] { expression.map { [$0] } ?? [] }
    public static func buildExpression(_ expression: [T]) -> [T] { expression }
    
    public static func buildOptional(_ component: [T]?) -> [T] { component ?? [] }
    public static func buildEither(first component: [T]) -> [T] { component }
    public static func buildEither(second component: [T]) -> [T] { component }
    public static func buildArray(_ components: [[T]]) -> [T] { components.flatMap { $0 } }
}

public typealias ElementBuilder = ArrayBuilder<AnyElement>

public extension Dictionary where Key == String {
    func string(_ key: String) -> String? {
        self[key] as? String
    }
    
    func int(_ key: String) -> Int? {
        self[key] as? Int
    }
    
    func double(_ key: String) -> Double? {
        self[key] as? Double
    }
    
    func bool(_ key: String) -> Bool? {
        self[key] as? Bool
    }
    
    func array(_ key: String) -> [Any]? {
        self[key] as? [Any]
    }
    
    func dictionary(_ key: String) -> [String: Any]? {
        self[key] as? [String: Any]
    }
    
    func function(_ key: String) -> (() -> Void)? {
        self[key] as? (() -> Void)
    }
}

public typealias DictValue = [String: Any]

public typealias StateSubscribers<T> = [UUID: (UUID, T) -> Void]
public typealias EmptyStateSubscribers = [UUID: () -> Void]

public protocol AnyState {
    var id: UUID { get }
    func unsubscribe(_ id: UUID)
    func subscribe(_ id: UUID, _ subscriber: @escaping () -> Void)
    var stringValue: String { get }
}

public final class State<T: CustomStringConvertible>: AnyState {
    public let id = UUID()
    private var subscribers: StateSubscribers<T> = [:]
    private var emptySubscribers: EmptyStateSubscribers = [:]
    
    private var _value: T
    
    public var value: T {
        set {
            _value = newValue
            notify()
        }
        get {
            guard var currentEl = RendererContext.currentBuildingElement else {
                return _value
            }
            
            if !currentEl.stateSubscribers.values.contains(where: { $0.id == self.id }) {
                let stateId = UUID()
                var skip = true
                subscribe(stateId) {
                    if (skip) {
                        skip = false
                        return
                    }
                    currentEl.update()
                }
                currentEl.stateSubscribers[stateId] = self
            }
            
            return _value
        }
    }
    
    public init(_ initial: T) {
        self._value = initial
    }
    
    public func subscribe(_ id: UUID, _ subscriber: @escaping (UUID, T) -> Void) {
        subscribers[id] = subscriber
        subscriber(id, value)
    }
    
    
    public func subscribe(_ id: UUID, _ subscriber: @escaping () -> Void) {
        emptySubscribers[id] = subscriber
        subscriber()
    }
    
    private func notify() {
        for (key, sub) in subscribers {
            sub(key, _value)
        }
        for (_, sub) in emptySubscribers {
            sub()
        }
    }
    
    public func unsubscribe(_ id: UUID) {
        subscribers.removeValue(forKey: id)
        emptySubscribers.removeValue(forKey: id)
    }
    
    public var stringValue: String {
        return value.description
    }
}

public typealias AnyElement = any Element
public protocol Element {
    var name: String { get }
    var refId: UUID { get }
    var stateSubscribers: [UUID: AnyState] { get set }
    var children: [AnyElement] { get set }
    var attributes: () -> DictValue { get set }
    var _attributes: DictValue { get set }
    var content: () -> [AnyElement] { get set }
    
    func unmount() -> Void
}

public extension Element {
    func unmount() {
        RendererContext.current!.unmountElement(self.refId)
        
        for (id, state) in stateSubscribers {
            state.unsubscribe(id)
        }
        
        for child in self.children {
            child.unmount()
            RendererContext.current!.unmountElement(child.refId)
        }
    }
    
    mutating func update() {
        let previousChildren = children
        let previousChildrenRefs = previousChildren.compactMap(\.refId)
        
        let (attributes, children) = children()
        self._attributes = attributes
        self.children = children
        
        let newChildrenRef = children.compactMap(\.refId)
        let isDifferent = previousChildrenRefs != newChildrenRef || previousChildren.count != children.count
        
        if isDifferent {
            for child in previousChildren {
                child.unmount()
            }
            
            RendererContext.current?.updateElement(self)
        }
        
    }
    
    func children() -> (
        attributes: DictValue,
        children: [AnyElement]
    ) {
        let previous = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = self    // set current el as parent dep
        let children = content()         // create children
        let attributes = attributes()
        RendererContext.currentBuildingElement = previous // restore previous
        return (attributes, children)
    }
}

public class Div: Element {
    public let name = "div"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    
    public init(attributes: @escaping () -> DictValue = {[:]}, @ElementBuilder _ content: @escaping () -> [AnyElement]) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self._attributes = attributes
        self.children = children
    }
}

public class Span: Element {
    
    public let name = "span"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}


public class Button: Element {
    public let name = "button"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement],
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

public class Text: Element {
    public enum Size: String {
        case normal, h1, h3, h5, h6
    }
    
    public var name = "text"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    public var text: String = ""
    
    required public init(
        _ text: String,
        size: Size = .normal,
        attributes: @escaping () -> DictValue = {[:]},
    ) {
        self.name = size.rawValue
        self.text = text
        self.content = { [] }
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
    
    public static func normal(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) -> Self {
        return Self.init(text, size: Size.normal, attributes: attributes)
    }
    
    public static func h1(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) -> Self {
        return Self.init(text, size: Size.h1, attributes: attributes)
    }
    
    public static func h3(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) -> Self {
        return Self.init(text, size: Size.h3, attributes: attributes)
    }
    
    public static func h5(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) -> Self {
        return Self.init(text, size: Size.h5, attributes: attributes)
    }
    
    public static func h6(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) -> Self {
        return Self.init(text, size: Size.h6, attributes: attributes)
    }
}

public class HyperLink: Element {
    public let name = "a"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

public class UnorderedList: Element {
    public let name = "ul"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [ListItem]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

public class ListItem: Element {
    public let name = "li"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

public class OrderedList: Element {
    public let name = "ol"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [ListItem]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

// TODO: thead, th, tfoot, td, tbody, table
public class Canvas: Element {
    public let name = "canvas"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

// image
public class Image: Element {
    public let name = "img"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement] = { [] }
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
    ) {
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

// TODO: select
// TODO: input -- here we need state from the actual UI, we don't want to reload the entire element if it expectss the value which is gonna require some changes to the render engine I think

// MARK: - Renderer
public protocol Renderer {
    associatedtype RefObject
    var root: any Element { get }
    var elementRefMap: [UUID: RefObject] { get set }
    
    func mount()
    
    // TODO: mount, mountElement, updateElement & unmountElement can all be 1 func (state machine)
    // For now we have some duplicated code
    func unmountElement(_  elementId: UUID)
    func mountElement(_ element: any Element, parentId: UUID)
    func updateElement(_ element: any Element)
}

public class DomRenderer: Renderer {
    public typealias RefObject = JSObject
    public let root: any Element
    public var elementRefMap: [UUID: JSObject] = [:]
    
    public init(root: any Element) {
        self.root = root
        RendererContext.current = self
    }
    
    public func mount() {
        let document = JSObject.global.document
        let container = document.getElementById("app").object!
        mountElement(root, into: container)
        print(root)
    }
    
    private func mountElement(_ element: any Element, into parent: JSObject) {
        print(element)
        let node = JSObject.global.document.createElement(element.name).object!
        elementRefMap[element.refId] = node
        
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
        
        
        print("mountElement: keys of \(element.name) is \(element._attributes.keys)")
        func vals(input: DictValue, node: JSObject) {
            print("mountElement-vals: keys of \(element.name) is \(element._attributes.keys)")
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
        
        if let textNode = element as? Text {
            node.innerText = textNode.text.jsValue
        }
        
//        if let buttonNode = element as? Button {
//            let clickHandler = JSClosure { _ in
//                if let buttonFunc = buttonNode._attributes.function("onClick") {
//                    buttonFunc()
//                }
//                return .undefined
//            }
//            node.onclick = clickHandler.jsValue
//        }
        
        _ = parent.appendChild!(node)
        
        print("children for \(element.name) \(element.children)")
        for child in element.children {
            mountElement(child, into: node)
        }
    }
    
    public func mountElement(_ element: any Element, parentId: UUID) {
        print("calling mount for \(element)")
        guard let parent = elementRefMap[parentId] else {
            print("Couldn't Find Parent Element")
            return
        }
        mountElement(element, into: parent)
    }
    
    public func unmountElement(_ elementId: UUID) {
        let node = elementRefMap[elementId]
        print("stuff", node, elementId, elementRefMap.keys)
        _ = node?.remove!()
        elementRefMap.removeValue(forKey: elementId)
    }
    
    public func updateElement(_ element: any Element) {
        let node = elementRefMap[element.refId]
        
        guard let node else {
            print("Couldn't Find Element To Update")
            return
        }
        
        if let textNode = element as? Text {
            node.innerText = textNode.text.jsValue
        }
        
        print("keys of \(element.name) is \(element._attributes.keys)")
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
        
        
        for child in element.children {
            mountElement(child, parentId: element.refId)
        }
    }
}
