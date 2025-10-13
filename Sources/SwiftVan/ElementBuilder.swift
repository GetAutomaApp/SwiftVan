//
//  ElementBuilder.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

@resultBuilder
public struct ArrayBuilder<T> {
    public static func buildBlock() -> [T] { [] }
    public static func buildBlock(_ components: [T]...) -> [T] { components.flatMap { $0 } }
    
    // wrap in phantom element - prevents re-rendering the whole parent
    public static func buildExpression(_ expression: T) -> [T] { [expression] }
    public static func buildExpression(_ expression: T?) -> [T] { expression.map { [$0] } ?? [] }
    public static func buildExpression(_ expression: [T]) -> [T] { expression }
    
    public static func buildOptional(_ component: [T]?) -> [T] { component ?? [] }
    public static func buildEither(first component: [T]) -> [T] { component }
    public static func buildEither(second component: [T]) -> [T] { component }
    // wrap in phantom element - prevents re-rendering the whole parent
    
    public static func buildArray(_ components: [[T]]) -> [T] { components.flatMap { $0 } }
}

public typealias ElementBuilder = ArrayBuilder<AnyElement>
