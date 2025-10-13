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
        Text.h3("HI")
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
