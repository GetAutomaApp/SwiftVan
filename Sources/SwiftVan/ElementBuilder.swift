//
//  ElementBuilder.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

@resultBuilder
public struct ElementBuilder {
    public static func buildBlock() -> [Element] { [] }
    public static func buildBlock(_ components: [Element]...) -> [Element] { components.flatMap { $0 } }
    
    // wrap in phantom element - prevents re-rendering the whole parent
    public static func buildExpression(_ expression: Element) -> [Element] { [expression] }
    public static func buildExpression(_ expression: Element?) -> [Element] { expression.map { [$0] } ?? [] }
    public static func buildExpression(_ expression: [Element]) -> [Element] { expression }
    // wrap in phantom element - prevents re-rendering the whole parent
    
    public static func buildArray(_ components: [[Element]]) -> [Element] { components.flatMap { $0 } }
}
