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
    // only gets set when we're building or updating conditionals
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

typealias HtmlBuilder = ArrayBuilder<AnyElement>

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
            // do we need rebuild on the entire project level (deadlock state until everythig is done building)
            // or do we just need it on a per element basis?
            // if we only need it on a per element basis does the element itself need to know its being subscribed to?
            // because if state knows about the element in the list of subscribers we can just call update
            // when we trigger an update & re-render we need to make sure that all states div cares about (if-else / any state) doesn't re-evaluate again, basically if we kick off a state, and we kick off another re-render we need to skip
            // do we need to have "old-value" implementation to do comparisons?
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
    var children: [AnyElement] { get }
    
    func unmount() -> Void
    func reevaluate() -> Void
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
    
    func update() {
        let previousChildren = children
        let previousChildrenRefs = previousChildren.compactMap(\.refId)
        
        reevaluate()
        
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
    
    @discardableResult
    func children(@HtmlBuilder _ content: () -> [AnyElement]) -> [AnyElement] {
        print("building \(name)")
        let previous = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = self    // set current el as parent dep
        let children = content()         // create children
        if let child = children[0] as? Text {
            print("\(name): children in children func \((children[0] as! Text).text)")
        } else {
            print("\(name): children in children func is \(children[0].name)")
        }
        RendererContext.currentBuildingElement = previous // now that we're out of the struct out
        print("done building \(name)")
        return children
    }
}

public class Div: Element {
    public let name = "div"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    private let content: () -> [AnyElement]
    
    public init(@HtmlBuilder _ content: @escaping () -> [AnyElement]) {
        self.content = content
        self.children = children(content)
    }
    
    public func reevaluate() {
        self.children = children(content)
    }
}

public class Span: Element {
    public let name = "span"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    private let content: () -> [AnyElement]
    
    public init(@HtmlBuilder _ content: @escaping () -> [AnyElement]) {
        self.content = content
        self.children = children(content)
    }
    
    public func reevaluate() {
        self.children = children(content)
    }
}


public class Button: Element {
    public let name = "button"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    private let content: () -> [AnyElement]
    let onClick: () -> Void
    
    public init(@HtmlBuilder _ content: @escaping () -> [AnyElement], onClick: @escaping () -> Void) {
        self.content = content
        self.onClick = onClick
        self.children = children(content)
    }
    
    public func reevaluate() {
        self.children = children(content)
    }
}


//public struct InterpolatedStateText: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
//    
//    public enum InterpolationType {
//        case string(String)
//        case state(AnyState)
//    }
//    
//    public struct StringInterpolation: StringInterpolationProtocol {
//        var indexes: [InterpolationType] = []
//        
//        public init(literalCapacity: Int, interpolationCount: Int) {
//            indexes.reserveCapacity(literalCapacity + interpolationCount)
//        }
//        
//        mutating public func appendLiteral(_ literal: String) {
//            indexes.append(.string(literal))
//        }
//        
//        mutating public func appendInterpolation(_ value: AnyState) {
//            indexes.append(.state(value))
//        }
//    }
//    
//    private let indexes: [InterpolationType]
//    
//    public init(stringLiteral value: String) {
//        self.indexes = [.string(value)]
//    }
//    
//    public init(stringInterpolation: StringInterpolation) {
//        print("init w/ interp")
//        self.indexes = stringInterpolation.indexes
//        print("done init w/ interp")
//    }
//    
//    public func subscribers() -> [AnyState] {
//        return indexes.compactMap { type in
//            switch type {
//            case .state(let val):
//                return val
//            case .string:
//                return nil
//            }
//        }
//    }
//    
//    public func toString() -> String {
//        var string = ""
//        
//        for index in indexes {
//            switch index {
//            case .string(let val):
//                string += val
//            case .state(let val):
//                string += val.stringValue
//            }
//        }
//        
//        return string
//    }
//}

public class Text: Element {
    public let name = "text"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    
    public var children: [AnyElement] = []
    public var text: String = ""
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func reevaluate() {}
}

//public class Condition: Element {
//    public let name = "div"
//    public let refId: UUID = UUID()
//    public var stateSubscribers: [UUID : AnyState] = [:]
//    public var children: [AnyElement] = []
//    
//    private let condition: () -> Bool
//    private let content: () -> [AnyElement]
//    
//    private var isMounted: Bool = false
//    
//    public init(
//        condition: @escaping () -> Bool,
//        states: [AnyState],
//        @HtmlBuilder content: @escaping () -> [any Element]
//    ) {
//        self.condition = condition
//        self.content = content
//        
//        for state in states {
//            let stateId = UUID()
//            stateSubscribers[stateId] = state
//            state.subscribe(stateId) {
//                self.reevaluate()
//            }
//        }
//        
//        reevaluate(initial: true)
//    }
//    
//    private func reevaluate(initial: Bool = false) {
//        print("re evaluating")
//        let shouldMount = condition()
//        
//        if shouldMount && initial {
//            children = content()
//            isMounted = true
//            return
//        }
//        
//        if !shouldMount && initial {
//            return
//        }
//        
//        guard let renderer = RendererContext.current else { return }
//        
//        if shouldMount && !isMounted {
//            children = content()
//            for child in children {
//                renderer.mountElement(child, parentId: self.refId)
//            }
//            isMounted = true
//        }
//        
//        if !shouldMount && isMounted {
//            for child in children {
//                child.unmount()
//                renderer.unmountElement(child.refId)
//            }
//            children = []
//            isMounted = false
//        }
//    }
//}

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
        
        if let textNode = element as? Text {
            node.innerText = textNode.text.jsValue
        }
        
        if let buttonNode = element as? Button {
            let clickHandler = JSClosure { _ in
                buttonNode.onClick()
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
            abort()
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
            abort()
        }
        
        if let textNode = element as? Text {
            node.innerText = textNode.text.jsValue
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

func UserComponent(user: User) -> AnyElement {
    return Span {
        Text("=== User Profile ===")
        Text("Name: \(user.name)")
        Text("Last Name: \(user.lastName)")
        Text("=== User Profile ===")
    }
}

// TODO: derived state
//let derivedState = DerivedState({state.value + 1}, [state])

let ui = Div {
    Button {
        Text("Increment + 1")
    } onClick: {
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
    }
    
    Span {
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

//// TODO: Create GlobalRenderer context so that we can call unmount from the element protocol
//// TODO: Test it by manually exposing the text id to global variable, then call unmount on it see what happens
//
//let intervalClosure = JSClosure { _ in
//    state.value += 1
//    print(state.value)
//    return .undefined
//}
//
//_ = JSObject.global.setInterval!(intervalClosure, 3000)
