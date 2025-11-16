//
//  Element.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

public typealias AnyElement = any Element
public protocol Element: AnyObject {
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
    
    func update() {
        let (newAttributes, _) = self.children(evalChildren: false)
        if self.name == "span" {
            print("spanUpdate attrs")
            print("spanUpdate prev: ", self._attributes)
            print("spanUpdate new: ", newAttributes)
        }
        self._attributes = newAttributes
        RendererContext.current?.updateElement(self, parentId: nil)
    }
    
    func children(evalChildren: Bool = true) -> (attributes: DictValue, children: [AnyElement]) {
        let previous = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = self    // set current el as parent dep
        let attributes = attributes()
        let children = evalChildren ? content() : self.children
        RendererContext.currentBuildingElement = previous // restore previous
        return (attributes, children)
    }
}
