//
//  Renderer.swift
//  SwiftVan
//
//  Created by Simon Ferns on 10/13/25.
//
import Foundation

public enum RendererContext {
    nonisolated(unsafe) public static var current: (any Renderer)?
    nonisolated(unsafe) public static var currentBuildingElement: Element?
}

public protocol Renderer {
    associatedtype RefObject
    var root: any Element { get }
    var elementRefMap: [UUID: (parentId: UUID?, element: RefObject)] { get set }
    
    func mount()
    
    // TODO: mount, mountElement, updateElement & unmountElement can all be 1 func (state machine)
    // For now we have some duplicated code
    func unmountElement(_  elementId: UUID)
    func mountElement(_ element: any Element, parentId: UUID)
    func updateElement(_ element: any Element, parentId: UUID?)
}
