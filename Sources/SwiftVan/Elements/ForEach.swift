//
//  ForEach.swift
//  SwiftVan
//
//  Created by Simon Ferns on 11/9/25.
//

import Foundation

public class ForEach: Element {
    public let name = "foreach"
    public let refId = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue = { [:] }
    public var _attributes: DictValue = [:]
    
    public init<T>(
        items: State<[T]>,
        @ElementBuilder _ content: @escaping (T) -> [AnyElement]
    ) {
        self.content = { [] }
        
        print("foreach: init called, starting initial render")
        
        func appendItems(_ itemsToAppend: [T], context: String) {
            print("foreach: appendItems called (\(context)), appending \(itemsToAppend.count) items")
            for (index, item) in itemsToAppend.enumerated() {
                print("foreach: rendering item[\(index)] = \(item)")
                let rendered = content(item)
                assert(rendered.count == 1, "foreach: ForEach currently supports exactly one child per item.")
                children.append(rendered[0])
                print(
                    "foreach: appended child[\(children.count - 1)] with element id \(rendered[0].refId)"
                )
            }
            print("foreach: appendItems complete — total children = \(children.count)")
            self.update()
        }
        
        appendItems(items.value, context: "initial render")
        
        var previousCount = items.value.count
        print("foreach: initial previousCount = \(previousCount)")
        
        let subscriptionId = UUID()
        print("foreach: subscribing to items with subscriptionId = \(subscriptionId)")
        
        self.stateSubscribers[subscriptionId] = items
        
        items.subscribe(subscriptionId) {
            let current = items.value
            print("foreach: subscription fired — currentCount = \(current.count), previousCount = \(previousCount)")
            
            if current.count > previousCount {
                let newItemCount = current.count - previousCount
                let newItems = Array(current.suffix(newItemCount))
                print("foreach: detected \(newItemCount) new item(s), appending now...")
                appendItems(newItems, context: "update (append new items)")
            } else if current.count < previousCount {
                print("foreach: detected item removal or truncation (previousCount \(previousCount) → \(current.count)) — no removal handling implemented yet")
            } else {
                print("foreach: item count unchanged — possible value updates but no new count")
            }
            
            previousCount = current.count
            print("foreach: updated previousCount = \(previousCount)")
        }
        
        print("foreach: init complete")
    }
}
