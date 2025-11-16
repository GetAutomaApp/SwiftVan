import Foundation
import SwiftVan

//struct User: CustomStringConvertible, Identifiable {
//    let id = UUID()
//    var name: String
//    var lastName: String
//    
//    var description: String {
//        "\(name) \(lastName)"
//    }
//}
//
//final class Counter {
//    func render(count: State<Int>) -> AnyElement {
//        Div {
//            Text.h3({"Count: \(count.value)"})
//            Button(onclick: { count.value += 1 }) { Text({"Increment"}) }
//            Counter2().render()
//        }
//    }
//}
//
//
final class Counter2 {
    var count = State(0)
    
    func render() -> AnyElement {
        Div {
            Text.h3({"Count(2): \(self.count.value)"})
            Button(onclick: { self.count.value += 1 }) { Text({"Increment"}) }
        }
    }
}
//
//let state = State(0)
//let state2 = State("true")
//let state3 = State([0])
//let state4 = State(User(name: "Simon", lastName: "Ferns"))
//let spanStyle = State(["background": "orange"])
//let state5 = State([100])
//
//let ui = Div(
//    attributes: {["style": ["background": "purple" ]]},
//) {
//    Button(
//        {[
//            "style": [
//                "background": state.value % 2 == 0 ? "green" : "red"
//            ]
//        ]},
//        onclick: {
//            state5.value.append(100*state.value)
//            print("--- removing bg")
//            if (spanStyle.value["background"] == nil) {
//                spanStyle.value["color"] = state.value % 2 == 0 ? "red" : "blue"
//            }
//            spanStyle.value.removeValue(forKey: "background")
//            print("--- removing bg")
//            print("set state1 in button")
//            state.value += 1
//            print("set state1 in button done")
//            
//            state3.value.append(state.value)
//            
//            state4.value.name = [
//                "Pete",
//                "John",
//                "Josh",
//                "Adam",
//                "William",
//                "Anonymous"
//            ].randomElement()!
//            
//            if (state.value % 2 == 0) { state2.value = "true" }
//            if (state.value % 3 != 0) { state2.value = "false" }
//            if (state.value > 10) { state2.value = "some value here"}
//            
//        }
//    ) {
//        Text.h3({"HI"})
//    }
//    
//    Span(
//        attributes: {
//            print("spanUpdate attrs set")
//            let attrs = ["style": spanStyle.value]
//            print("spanUpdate attrs set:", attrs)
//            return attrs
//        },
//        ) {
//        Text({"Count Is \(state.value)"})
//        
//        Counter().render(count: state)
//            
//        If(
//            {state.value % 2 == 0}, states: [state]
//        ) {
//            Text({"This Is Even"})
//        } else: {
//            Text({"This Is Odd"})
//        }
//    }
//    
////    ForEach(items: state5) { a in
////        Text({"Item Is: \(a)"})
////    }
//}

let state = State(1)
let state2 = State([100])

let ui = Div {
    Button({[:]}, onclick: {
        state.value += 1
        state2.value.append(state.value*10)
    }) {
        Text({"Hi"})
    }
    ForEach(items: state2) { a in
        Text({"HI HI HI"})
    }
    If({state.value % 2 == 0}, states: [state]) {
        Text({"Is Even"})
    }
    Else: {
        Text({"Is Odd"})
    }
}

let renderer = DomRenderer(root: ui)
renderer.mount()

