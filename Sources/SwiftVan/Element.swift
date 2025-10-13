//
//  Element.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

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
            
            RendererContext.current?.updateElement(self, parentId: nil)
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
