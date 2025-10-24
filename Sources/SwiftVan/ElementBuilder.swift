//
//  ElementBuilder.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

final class ComponentCache {
    nonisolated(unsafe) static let shared = ComponentCache()
    var instances: [String: any Component] = [:]
}

@resultBuilder
public struct ElementBuilder {
    public static func buildBlock() -> [AnyElement] { [] }
    public static func buildBlock(_ components: [AnyElement]...) -> [AnyElement] { components.flatMap { $0 } }
    
    // wrap in phantom element - prevents re-rendering the whole parent
    public static func buildExpression(_ expression: AnyElement) -> [AnyElement] { [expression] }
    public static func buildExpression(_ expression: AnyElement?) -> [AnyElement] { expression.map { [$0] } ?? [] }
    public static func buildExpression(_ expression: [AnyElement]) -> [AnyElement] { expression }
    
    public static func buildOptional(_ component: [AnyElement]?) -> [AnyElement] { component ?? [] }
    public static func buildEither(first component: [AnyElement]) -> [AnyElement] { component }
    public static func buildEither(second component: [AnyElement]) -> [AnyElement] { component }
    // wrap in phantom element - prevents re-rendering the whole parent
    
    public static func buildArray(_ components: [[AnyElement]]) -> [AnyElement] { components.flatMap { $0 } }
    
    public static func buildExpression(_ expression: (any Component.Type)) -> [AnyElement] {
        // hoekom bestaan parent building element nie in hierdie contex nie?
        // moet mens eerder builder context maak? ::
        let parentCacheKey = RendererContext.currentBuildingElement?.cacheKey ?? "root"
        
        let siblingIndex: Int
        if let parent = RendererContext.currentBuildingElement {
            siblingIndex = parent.children.filter { type(of: $0) == expression }.count
        } else {
            siblingIndex = 0
        }
        
        let cacheKey = "\(parentCacheKey)/\(String(describing: expression))[\(siblingIndex)]"
        print("cache:", cacheKey)
        
        let instance: any Component
        if let existing = ComponentCache.shared.instances[cacheKey] {
            instance = existing
        } else {
            let newInstance = expression.init()
            newInstance.cacheKey = cacheKey
            ComponentCache.shared.instances[cacheKey] = newInstance
            instance = newInstance
        }
        
        let previousElement = RendererContext.currentBuildingElement
        RendererContext.currentBuildingElement = instance as? (any Element)
        
        let rendered = instance.render()
        
        RendererContext.currentBuildingElement = previousElement
        
        return [rendered]
    }
}


