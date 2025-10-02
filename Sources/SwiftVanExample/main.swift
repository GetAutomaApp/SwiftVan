//
//  Untitled.swift
//  SwiftVan4
//
//  Created by Simon Ferns on 9/29/25.
//
import JavaScriptKit
import Foundation

@resultBuilder
public enum HtmlBuilder {
    public static func buildBlock(_ components: any Element...) -> [any Element] {
        components
    }
}

public typealias StateSubscribers<T> = [UUID: (UUID, T) -> Void]
public typealias EmptyStateSubscribers = [UUID: () -> Void]

public protocol AnyState {
    func unsubscribe(_ id: UUID)
    func subscribe(_ id: UUID, _ subscriber: @escaping () -> Void)
    var stringValue: String { get }
}

public final class State<T: CustomStringConvertible>: AnyState {
    private var subscribers: StateSubscribers<T> = [:]
    private var emptySubscribers: EmptyStateSubscribers = [:]
    
    public var value: T {
        didSet { notify() }
    }
    
    public init(_ initial: T) {
        self.value = initial
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
            sub(key, value)
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
}

public extension Element {
    func unmount() {
        for (id, state) in stateSubscribers {
            state.unsubscribe(id)
        }
        
        for child in self.children {
            child.unmount()
            RendererContext.current!.unmountElement(child.refId)
        }
    }
    
    func update() {
        RendererContext.current?.updateElement(self)
    }
}

public class Div: Element {
    public let name = "div"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    
    public var children: [AnyElement]
    
    public init(@HtmlBuilder _ content: () -> [AnyElement]) {
        self.children = content()
    }
}

public struct InterpolatedStateText: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    
    public enum InterpolationType {
        case string(String)
        case state(AnyState)
    }
    
    public struct StringInterpolation: StringInterpolationProtocol {
        var indexes: [InterpolationType] = []
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            indexes.reserveCapacity(literalCapacity + interpolationCount)
        }
        
        mutating public func appendLiteral(_ literal: String) {
            indexes.append(.string(literal))
        }
        
        mutating public func appendInterpolation(_ value: AnyState) {
            indexes.append(.state(value))
        }
    }
    
    private let indexes: [InterpolationType]
    
    public init(stringLiteral value: String) {
        self.indexes = [.string(value)]
    }
    
    public init(stringInterpolation: StringInterpolation) {
        self.indexes = stringInterpolation.indexes
    }
    
    public func subscribers() -> [AnyState] {
        return indexes.compactMap { type in
            switch type {
            case .state(let val):
                return val
            case .string:
                return nil
            }
        }
    }
    
    public func toString() -> String {
        var string = ""
        
        for index in indexes {
            switch index {
            case .string(let val):
                string += val
            case .state(let val):
                string += val.stringValue
            }
        }
        
        return string
    }
}

public class Text: Element {
    public let name = "text"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    
    public var children: [AnyElement] = []
    public var text: String = ""
    
    public init(_ text: InterpolatedStateText) {
        let subscribers = text.subscribers()
        if subscribers.isEmpty {
            self.text = text.toString()
            return
        }
        
        for subscriber in subscribers {
            let stateId: UUID = .init()
            subscriber.subscribe(stateId) {
                self.text = text.toString()
                self.update()
            }
            self.stateSubscribers[stateId] = subscriber
        }
    }
    
    public init<T>(_ state: State<T>) {
        let stateId: UUID = .init()
        state.subscribe(stateId) {id, value in
            print("text updated")
            self.text = value.description
            self.update()
        }
        self.stateSubscribers[stateId] = state
    }
}

public class Condition: Element {
    public let name = "div"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID : AnyState] = [:]
    public var children: [AnyElement] = []
    
    private let condition: () -> Bool
    private let content: () -> [AnyElement]
    
    private var isMounted: Bool = false
    
    public init(
        condition: @escaping () -> Bool,
        states: [AnyState],
        @HtmlBuilder content: @escaping () -> [any Element]
    ) {
        self.condition = condition
        self.content = content
        
        for state in states {
            let stateId = UUID()
            stateSubscribers[stateId] = state
            state.subscribe(stateId) {
                self.reevaluate()
            }
        }
        
        reevaluate(initial: true)
    }
    
    private func reevaluate(initial: Bool = false) {
        print("re evaluating")
        let shouldMount = condition()
        
        if shouldMount && initial {
            children = content()
            isMounted = true
            return
        }
        
        if !shouldMount && initial {
            return
        }
        
        guard let renderer = RendererContext.current else { return }
        
        if shouldMount && !isMounted {
            children = content()
            for child in children {
                renderer.mountElement(child, parentId: self.refId)
            }
            isMounted = true
        }
        
        if !shouldMount && isMounted {
            for child in children {
                child.unmount()
                renderer.unmountElement(child.refId)
            }
            children = []
            isMounted = false
        }
    }
}

public enum RendererContext {
    nonisolated(unsafe) public static var current: (any Renderer)?
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
    }
    
    private func mountElement(_ element: any Element, into parent: JSObject) {
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
        
        for child in element.children {
            mountElement(child, into: node)
        }
        
        _ = parent.appendChild!(node)
    }
    
    public func mountElement(_ element: any Element, parentId: UUID) {
        guard let parent = elementRefMap[parentId] else {
            print("Couldn't Find Parent Element")
            abort()
        }
        mountElement(element, into: parent)
    }
    
    public func unmountElement(_ elementId: UUID) {
        let node = elementRefMap[elementId]
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
    }
}



let state = State(0)

// TODO: derived state
//let derivedState = DerivedState({state.value + 1}, [state])

let ui = Div {
    Condition(condition: {state.value % 2 == 0}, states: [state]) {
        Text("Value is Even")
    }
    Condition(condition: {state.value % 2 != 0}, states: [state]) {
        Text("Value is Odd")
    }
    Text("Count Is \(state)")
}

let renderer = DomRenderer(root: ui)
renderer.mount()

// TODO: Create GlobalRenderer context so that we can call unmount from the element protocol
// TODO: Test it by manually exposing the text id to global variable, then call unmount on it see what happens

let intervalClosure = JSClosure { _ in
    state.value += 1
    print(state.value)
    return .undefined
}

_ = JSObject.global.setInterval!(intervalClosure, 3000)
