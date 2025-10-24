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
    var cacheKey: String { get set }
    
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
        let (attributes, children) = children()
        self._attributes = attributes
        self.children = children
        
        RendererContext.current?.updateElement(self, parentId: nil)
        
    }
    
    func children() -> (
        attributes: DictValue,
        children: [AnyElement]
    ) {
        // Compute cache key relative to parent
        let parentCacheKey = RendererContext.currentBuildingElement?.cacheKey ?? "root"
        let myCacheKey = "\(parentCacheKey)/\(name)"
        
        var mutableSelf = self
        mutableSelf.cacheKey = myCacheKey
        
        // Set current element for children
        let previousElement = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = mutableSelf
        
        let children = content()
        let attributes = attributes()
        
        // Restore
        RendererContext.currentBuildingElement = previousElement
        
        return (attributes, children)
    }


}
