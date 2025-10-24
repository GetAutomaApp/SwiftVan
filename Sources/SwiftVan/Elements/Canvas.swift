//
//  Canvas.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

// TODO: thead, th, tfoot, td, tbody, table
public class Canvas: Element {
    public var cacheKey: String = ""
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
