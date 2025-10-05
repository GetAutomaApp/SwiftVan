//
//  Untitled.swift
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
struct ArrayBuilder<T> {
    static func buildBlock() -> [T] { [] }
    static func buildBlock(_ components: [T]...) -> [T] { components.flatMap { $0 } }
    
    static func buildExpression(_ expression: T) -> [T] { [expression] }
    static func buildExpression(_ expression: T?) -> [T] { expression.map { [$0] } ?? [] }
    static func buildExpression(_ expression: [T]) -> [T] { expression }
    
    static func buildOptional(_ component: [T]?) -> [T] { component ?? [] }
    static func buildEither(first component: [T]) -> [T] { component }
    static func buildEither(second component: [T]) -> [T] { component }
    static func buildArray(_ components: [[T]]) -> [T] { components.flatMap { $0 } }
}

typealias ElementBuilder = ArrayBuilder<AnyElement>

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
            
            print("starting sub for element \(currentEl.name)")
            if !currentEl.stateSubscribers.values.contains(where: { $0.id == self.id }) {
                print("subbing")
                let stateId = UUID()
                var skip = true
                subscribe(stateId) {
                    print("skip is \(skip)")
                    if (skip) {
                        skip = false
                        return
                    }
                    currentEl.update()
                }
                currentEl.stateSubscribers[stateId] = self
                print(currentEl.stateSubscribers.values)
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
        print("notifying")
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
        
        print("is different \(isDifferent)")
        print("previous child refs \(previousChildrenRefs)")
        print("previous child refs \(newChildrenRef)")
        
        if isDifferent {
            for child in previousChildren {
                print("unmounting \(child.name)")
                child.unmount()
            }
            
            RendererContext.current?.updateElement(self)
        }
        
    }
    
    func children() -> (
        attributes: DictValue,
        children: [AnyElement]
    ) {
        print("building \(name)")
        let previous = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = self    // set current el as parent dep
        let children = content()         // create children
        let attributes = attributes()
        if children.isEmpty {
            print("\(name): children in children func is empty")
        } else if let firstText = children[0] as? Text {
            print("\(name): children in children func Text -> \(firstText.text)")
        } else {
            print("\(name): children in children func is \(children[0].name)")
        }
        RendererContext.currentBuildingElement = previous // restore previous
        print("done building \(name)")
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
    public let name = "text"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    public var text: String = ""
    
    public init(
        _ text: String,
        attributes: @escaping () -> DictValue = {[:]},
    ) {
        self.text = text
        self.content = { [] }
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}

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
        _ = node.style = JSObject().jsValue
        if let styles = element._attributes.dictionary("style") {
            for key in styles.keys {
                if let value = styles.string(key) {
                    _ = node.style.setProperty(key, value)
                }
            }
        }

        if let textNode = element as? Text {
            node.innerText = textNode.text.jsValue
        }
        
        if let buttonNode = element as? Button {
            let clickHandler = JSClosure { _ in
                if let buttonFunc = buttonNode._attributes.function("onClick") {
                    buttonFunc()
                }
                return .undefined
            }
            node.onclick = clickHandler.jsValue
        }
        
        print("children for \(element.name) \(element.children)")
        for child in element.children {
            mountElement(child, into: node)
        }
        
        _ = parent.appendChild!(node)
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
        
        // TODO - Fix Rendering Styles Please
        _ = node.style = JSObject().jsValue
        if let styles = element._attributes.dictionary("style") {
            for key in styles.keys {
                print("properties \(styles)")
                if let value = styles.string(key) {
                    _ = node.style.setProperty(key, value)
                }
            }
        }
        
        for child in element.children {
            mountElement(child, parentId: element.refId)
        }
    }
}

struct User: CustomStringConvertible {
    var name: String
    var lastName: String
    
    var description: String {
        "\(name) \(lastName)"
    }
}

let state = State(0)
let state2 = State("true")
let state3 = State([0])
let state4 = State(User(name: "Simon", lastName: "Ferns"))
let spanStyle = State(["background": "orange"])

// todo create a "Component" protocol to make this a bit easier to manage
func UserComponent(user: User) -> AnyElement {
    return
        Span {
            Text("=== User Profile ===")
            Text("Name: \(user.name)")
            Text("Last Name: \(user.lastName)")
            Text("=== User Profile ===")
        }
}

let ui = Div(
    attributes: {["style": ["background": "purple" ]]},
) {
    Button(
        attributes: {
            ["onClick": {
                print("--- removing bg")
                spanStyle.value.removeValue(forKey: "background")
                print("--- removing bg")
                print("set state1 in button")
                state.value += 1
                print("set state1 in button done")
                
                state3.value.append(state.value)
                
                state4.value.name = [
                    "Pete",
                    "John",
                    "Josh",
                    "Adam",
                    "William",
                    "Anonymous"
                ].randomElement()!
                
                if (state.value % 2 == 0) { state2.value = "true" }
                if (state.value % 3 != 0) { state2.value = "false" }
                if (state.value > 10) { state2.value = "some value here"}
            },
             "style": [
                "background": state.value % 2 == 0 ? "green" : "red"
             ]
            ]
        }
    ) {
        Text("Increment + 1")
    }
    
    Span(
        attributes: {["style": spanStyle.value]},
        ) {
        Text("Count Is \(state.value)")
        
        if state.value % 2 == 0 {
            Text("Value Is Even")
        } else {
            Text("Value is Odd")
        }
        
        switch (state2.value) {
        case "true":
            Text("State 2 is True")
        case "false":
            Text("State 2 is False")
        default:
            Text("State 2 is \(state2.value)")
        }
    }
    
    
    Div {
        UserComponent(user: state4.value)
    }
    
    Div {
        for value in state3.value {
            Text("- List Value Here \(value)")
        }
    }
    
    Div {
        Text("Don't Be Updated")
    }
}

let renderer = DomRenderer(root: ui)
renderer.mount()
