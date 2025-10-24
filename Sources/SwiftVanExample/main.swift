import Foundation
import SwiftVan

struct User: CustomStringConvertible {
    var name: String
    var lastName: String
    
    var description: String {
        "\(name) \(lastName)"
    }
}

let state = State(0)
let state2 = State("true")
let state3 = State([0])
let state4 = State(User(name: "Simon", lastName: "Ferns"))
let spanStyle = State(["background": "orange"])

//public class UserUserDefined: Element {
//    public let name = "div"
//    public let refId: UUID = UUID()
//    public var stateSubscribers: [UUID: AnyState] = [:]
//    public var children: [AnyElement] = []
//    public var content: () -> [AnyElement]
//    public var attributes: () -> DictValue
//    public var _attributes: DictValue = [:]
//    
//    init(user: User) {
//        self.content = { [] }
//        self.attributes = {[:]}
//        self.content = { [self.render(user: user)] }
//        let (attributes, children) = children()
//        self.children = children
//        self._attributes = attributes
//    }
//    
//    func render(user: User) -> AnyElement {
//        return Div {
//            Text.h1("=== User Profile ===")
//            Text.h5("Name: \(user.name)")
//            Text.h5("Last Name: \(user.lastName)")
//            Text.h1("=== User Profile ===")
//        }
//    }
//}

final class Counter: BaseComponent {
    var count = State(0)
    
    override func render() -> AnyElement {
        Div {
            Text.h3({"Count: \(self.count.value)"})
            Button(onclick: { self.count.value += 1 }) { Text({"Increment"}) }
            Counter2.self
        }
    }
}


final class Counter2: BaseComponent {
    var count = State(0)
    
    override func render() -> AnyElement {
        Div {
            Text.h3({"Count(2): \(self.count.value)"})
            Button(onclick: { self.count.value += 1 }) { Text({"Increment"}) }
        }
    }
}


// Currently we're re-building the parent elements that rely on a state variable, the problem is we're resetting the ids for all the children we're building.
// We don't want to do that and only remove / add the children that are being removed / added
// We also only want to update the properties on the children rather than re-rendering them completely
// This will require that we don't call content() when the parent updates again, because that rebuilds the entire tree from that point
// We only want to call it when there is an if-else condition in the tree, which can be indicated by assigning hasOptional to the parent element, we'll also need to store the previous value to determine if we need to change anything if the condition changed or not right?
// We also want to have when attributes change, don't re-render, only update the attributes, we can figure this out by simply knowing if it is an optional or not
// Then we don't need the component cache at all, because we can ust call Component() and the state variables should persist except in optional changing cases (which we expect right?)
// isOptionalChildren should be the simplest approach then
// What happens for lists? How do we add a new item? Or do we just not want to allow for-each loop, rather only allow ForEach() custom element, because we jsut want to add children, not re-render the whole thing right?

let ui = Div(
    attributes: {["style": ["background": "purple" ]]},
) {
//    Button(
//        attributes: {
//            ["onclick": {
//                print("--- removing bg")
//                spanStyle.value.removeValue(forKey: "background")
//                print("--- removing bg")
//                print("set state1 in button")
//                state.value += 1
//                print("set state1 in button done")
//                
//                state3.value.append(state.value)
//                
//                state4.value.name = [
//                    "Pete",
//                    "John",
//                    "Josh",
//                    "Adam",
//                    "William",
//                    "Anonymous"
//                ].randomElement()!
//                
//                if (state.value % 2 == 0) { state2.value = "true" }
//                if (state.value % 3 != 0) { state2.value = "false" }
//                if (state.value > 10) { state2.value = "some value here"}
//            },
//             "style": [
//                "background": state.value % 2 == 0 ? "green" : "red"
//             ]
//            ]
//        }
//    ) {
//        Text.h3("Increment + 1")
//    }
    
    Button(
        {[
            "style": [
//                "background": state.value % 2 == 0 ? "green" : "red"
            ]
        ]},
        onclick: {
            print("--- removing bg")
            spanStyle.value.removeValue(forKey: "background")
            print("--- removing bg")
            print("set state1 in button")
            state.value += 1
            print("set state1 in button done")
            
            state3.value.append(state.value)
            
            state4.value.name = [
                "Pete",
                "John",
                "Josh",
                "Adam",
                "William",
                "Anonymous"
            ].randomElement()!
            
            if (state.value % 2 == 0) { state2.value = "true" }
            if (state.value % 3 != 0) { state2.value = "false" }
            if (state.value > 10) { state2.value = "some value here"}
        }
    ) {
        Text.h3({"HI \(state.value)"})
    }
    
    Div(
        attributes: {[
            "style": [
                                "background": state.value % 2 == 0 ? "green" : "red"
            ]
        ]},
    ) {
        Counter.self
    }
//
//    Span(
//        attributes: {["style": spanStyle.value]},
//        ) {
//        Text("Count Is \(state.value)")
//        
//        if state.value % 2 == 0 {
//            Text("Value Is Even")
//        } else {
//            Text("Value is Odd")
//        }
//        
//        switch (state2.value) {
//        case "true":
//            Text("State 2 is True")
//        case "false":
//            Text("State 2 is False")
//        default:
//            Text("State 2 is \(state2.value)")
//        }
//    }
//    
//
//    Div {
//        UserUserDefined(user: state4.value)
//    }
//
//    Div {
//        for value in state3.value {
//            Text("- List Value Here \(value)")
//        }
//    }
//    
//    Div {
//        Text("Don't Be Updated")
//    }
    
    Image(attributes: {["src": "https://picsum.photos/200"]} )
}

let renderer = DomRenderer(root: ui)
renderer.mount()
