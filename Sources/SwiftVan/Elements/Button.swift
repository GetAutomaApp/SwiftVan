//
//  Button.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

public class Button: Element {
    public let name = "button"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement],
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
    
    public convenience init(
        _ attributes: @escaping () -> DictValue = {[:]},
        onclick: @escaping () -> Void = {},
        @ElementBuilder _ content: @escaping () -> [AnyElement],
    ) {
        let attrs = {
            var attrs = attributes()
            attrs["onclick"] = onclick
            return attrs
        }
        self.init(attributes: attrs, content)
    }
}
