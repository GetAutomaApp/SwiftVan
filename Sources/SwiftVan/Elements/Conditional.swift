//
//  Conditional.swift
//  SwiftVan
//
//  Created by Simon Ferns on 11/1/25.
//

import Foundation

public class If: Element {
    public let name = "conditional"
    public let refId: UUID = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var condition: () -> Bool
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue = { [:] }

    public var _attributes: DictValue = [:]

    private var lastConditionResult: Bool? = nil

    public init(
        _ condition: @escaping () -> Bool,
        states: [AnyState] = [],
        @ElementBuilder If: @escaping () -> [AnyElement],
        @ElementBuilder Else: @escaping () -> [AnyElement] = { [] },
    ) {
        print("initializing conditional")
        // TODO: edit "content" function so that when we call it it will either build UI, return existing components, or return emtpy array
        self.condition = condition

        let result = self.condition()
        if result {
            self.content = If
            self.children = If()
        } else {
            self.content = Else
            self.children = Else()
        }

        // this causes a lag spike, figure out why
        states.forEach { state in
            state.subscribe(UUID()) {
                let result = self.condition()
                if result && result != self.lastConditionResult {
                    self.children.forEach { child in
                        child.unmount()
                    }
                    self.children = If()
                } else if !result {
                    self.children.forEach { child in
                        child.unmount()
                    }
                    self.children = Else()
                }
                self.lastConditionResult = result
                self.update()
            }
        }
    }
}
