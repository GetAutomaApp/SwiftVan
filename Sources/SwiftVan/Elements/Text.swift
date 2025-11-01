//
//  Text.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

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
    
    required public init(
        _ text: String,
        size: Size = .normal,
        attributes: @escaping () -> DictValue = {[:]},
    ) {
        self.name = size.rawValue
        self.content = { [] }
        self.attributes = {
            print("updating innerText")
            var attrs = attributes()
            attrs["innerText"] = text
            return attrs
        }
        let attributes = children()
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
