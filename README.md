# SwiftVan Documentation

## 🚀 Quick Start

**Get started quickly with our GitHub template:**

👉 **[https://github.com/getautomaapp/swiftvanbase](https://github.com/getautomaapp/swiftvanbase)**

Use this template to bootstrap your SwiftVan project with all the necessary configuration and setup!

---

## Overview

**SwiftVan** is a reactive UI framework for Swift that compiles to WebAssembly (WASM) and renders to the DOM. It provides a SwiftUI-like declarative syntax for building web applications using Swift.

## Table of Contents

- [Architecture](#architecture)
- [Core Concepts](#core-concepts)
- [Components](#components)
- [State Management](#state-management)
- [Available Elements](#available-elements)
- [Getting Started](#getting-started)
- [Examples](#examples)

---

## Architecture

SwiftVan follows a reactive, component-based architecture:

```
┌─────────────────┐
│   Swift Code    │
│  (Components)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Elements     │ ◄── State subscriptions
│   (UI Tree)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   DomRenderer   │
│ (Virtual DOM)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Browser DOM   │
└─────────────────┘
```

### Key Components:

1. **Elements** - Building blocks of the UI (Div, Button, Text, etc.)
2. **State** - Reactive state management system
3. **Renderer** - Manages the virtual DOM and updates
4. **ElementBuilder** - Result builder for declarative syntax

---

## Core Concepts

### 1. Elements

All UI components conform to the `Element` protocol:

```swift
public protocol Element: AnyObject {
    var name: String { get }              // HTML tag name
    var refId: UUID { get }               // Unique identifier
    var stateSubscribers: [UUID: AnyState] { get set }
    var children: [AnyElement] { get set }
    var attributes: () -> DictValue { get set }
    var _attributes: DictValue { get set }
    var content: () -> [AnyElement] { get set }
    
    func unmount() -> Void
}
```

### 2. Reactive State

State changes automatically trigger UI updates through a subscription system:

```swift
let count = State(0)
count.value += 1  // Automatically updates all subscribed UI elements
```

### 3. Result Builders

SwiftVan uses Swift's `@resultBuilder` to enable declarative syntax:

```swift
Div {
    Text({ "Hello" })
    Button { Text({ "Click me" }) }
}
```

---

## State Management

### Creating State

```swift
let counter = State(0)
let name = State("John")
let items = State([1, 2, 3])
```

### Reading State

When you read `state.value` inside an element's attributes or content, the element automatically subscribes to that state:

```swift
Text({ "Count: \(counter.value)" })  // Auto-subscribes to counter
```

### Updating State

```swift
counter.value += 1  // Triggers re-render of subscribed elements
```

### State Lifecycle

- **Subscribe**: Elements automatically subscribe when accessing `state.value`
- **Notify**: State notifies all subscribers when value changes
- **Unsubscribe**: Elements unsubscribe when unmounted

---

## Available Elements

### Container Elements

#### `Div`
Generic container element (renders as `<div>`)

```swift
Div(attributes: { [:] }) {
    // children
}
```

#### `Span`
Inline container element (renders as `<span>`)

```swift
Span(attributes: { [:] }) {
    // children
}
```

### Text Elements

#### `Text`
Renders text with different heading sizes

```swift
// Different sizes
Text.normal({ "Regular text" })
Text.h1({ "Heading 1" })
Text.h3({ "Heading 3" })
Text.h5({ "Heading 5" })
Text.h6({ "Heading 6" })

// With attributes
Text.h1({ "Title" }, attributes: {
    ["style": ["color": "blue"]]
})
```

### Interactive Elements

#### `Button`
Clickable button element

```swift
Button(onclick: {
    // Handle click
}) {
    Text({ "Click me" })
}

// With attributes
Button({ ["style": ["background": "blue"]] }, onclick: {
    // Handle click
}) {
    Text({ "Styled Button" })
}
```

### Media Elements

#### `Image`
Image element (renders as `<img>`)

```swift
Image(attributes: {
    ["src": "image.png", "alt": "Description"]
})
```

#### `Canvas`
Canvas element for drawing

```swift
Canvas(attributes: {
    ["width": 800, "height": 600]
}) {
    // children
}
```

### List Elements

#### `OrderedList`
Ordered list (renders as `<ol>`)

```swift
OrderedList(attributes: { [:] }) {
    ListItem { Text({ "First" }) }
    ListItem { Text({ "Second" }) }
}
```

#### `UnorderedList`
Unordered list (renders as `<ul>`)

```swift
UnorderedList(attributes: { [:] }) {
    ListItem { Text({ "Item 1" }) }
    ListItem { Text({ "Item 2" }) }
}
```

#### `ListItem`
List item (renders as `<li>`)

```swift
ListItem(attributes: { [:] }) {
    Text({ "Item content" })
}
```

### Navigation Elements

#### `HyperLink`
Hyperlink element (renders as `<a>`)

```swift
HyperLink(attributes: {
    ["href": "https://example.com"]
}) {
    Text({ "Visit Example" })
}
```

---

## Control Flow Elements

### `If` / Conditional

Conditionally render elements based on state:

```swift
let isLoggedIn = State(false)

If({ isLoggedIn.value }, states: [isLoggedIn]) {
    Text({ "Welcome back!" })
} Else: {
    Text({ "Please log in" })
}
```

**Important**: Pass the states array to ensure the conditional re-evaluates when state changes.

### `ForEach`

Render a list of items from a state array:

```swift
let items = State([1, 2, 3])

ForEach(items: items) { item in
    Text({ "Item: \(item)" })
}
```

**Features**:
- Automatically updates when items are added
- Each item must render exactly one child element
- Subscribes to the state array for reactive updates

---

## Attributes System

### Basic Attributes

Attributes are passed as dictionaries:

```swift
Div(attributes: {
    ["id": "container", "class": "main"]
}) {
    // children
}
```

### Nested Attributes (Styles)

Styles use nested dictionaries:

```swift
Div(attributes: {
    ["style": [
        "background": "blue",
        "color": "white",
        "padding": "10px"
    ]]
}) {
    // children
}
```

### Dynamic Attributes

Attributes can use state values:

```swift
let color = State("red")

Div(attributes: {
    ["style": ["background": color.value]]
}) {
    // children
}
```

### Event Handlers

Event handlers are passed as closures:

```swift
Button({ [:] }, onclick: {
    print("Button clicked!")
}) {
    Text({ "Click" })
}
```

---

## Renderer System

### DomRenderer

The `DomRenderer` manages the virtual DOM and updates:

```swift
let ui = Div {
    Text({ "Hello World" })
}

let renderer = DomRenderer(root: ui)
renderer.mount()
```

### Rendering Process

1. **Mount**: Initial render of the element tree
2. **Update**: Diff props and update only changed attributes
3. **Unmount**: Clean up elements and unsubscribe from state

### Props Diffing

The renderer efficiently updates only changed attributes:

```swift
struct PropsDiff {
    var added: [String: Any]      // New attributes
    var changed: [String: Any]    // Modified attributes
    var removed: [String]         // Removed attributes
}
```

---

## Getting Started

### Prerequisites

- Swift 6.1+
- SwiftWasm toolchain
- Node.js (for development server)

### Installation

1. Clone the repository:
```bash
git clone --recurse-submodules --remote-submodules https://github.com/GetAutomaApp/SwiftVan.git
cd SwiftVan
npm install
```

2. Build the project:
```bash
swift build --triple wasm32-unknown-wasi
```

3. Run the development server:
```bash
npm run dev
```

### Project Structure

```
SwiftVan/
├── Sources/
│   ├── SwiftVan/           # Core framework
│   │   ├── Element.swift
│   │   ├── State.swift
│   │   ├── Renderer.swift
│   │   ├── ElementBuilder.swift
│   │   ├── Elements/       # UI elements
│   │   └── RenderTargets/  # DomRenderer
│   └── SwiftVanExample/    # Example app
│       └── main.swift
├── Package.swift
└── index.html
```

---

## Examples

### Simple Counter

```swift
let count = State(0)

let ui = Div {
    Text.h1({ "Counter: \(count.value)" })
    Button(onclick: { count.value += 1 }) {
        Text({ "Increment" })
    }
}

let renderer = DomRenderer(root: ui)
renderer.mount()
```

### Todo List

```swift
let todos = State(["Buy milk", "Walk dog"])
let newTodo = State("")

let ui = Div {
    Text.h1({ "Todo List" })
    
    ForEach(items: todos) { todo in
        Div {
            Text({ todo })
        }
    }
    
    Button(onclick: {
        todos.value.append("New task")
    }) {
        Text({ "Add Todo" })
    }
}

let renderer = DomRenderer(root: ui)
renderer.mount()
```

### Conditional Rendering

```swift
let isVisible = State(true)

let ui = Div {
    Button(onclick: { isVisible.value.toggle() }) {
        Text({ "Toggle" })
    }
    
    If({ isVisible.value }, states: [isVisible]) {
        Text({ "I'm visible!" })
    } Else: {
        Text({ "I'm hidden!" })
    }
}

let renderer = DomRenderer(root: ui)
renderer.mount()
```

### Component Pattern

```swift
final class Counter {
    var count = State(0)
    
    func render() -> AnyElement {
        Div {
            Text.h3({ "Count: \(self.count.value)" })
            Button(onclick: { self.count.value += 1 }) {
                Text({ "Increment" })
            }
        }
    }
}

let counter = Counter()
let renderer = DomRenderer(root: counter.render())
renderer.mount()
```

---

## Advanced Topics

### Component Lifecycle

Components can manage their own state and lifecycle:

```swift
class MyComponent: BaseComponent {
    var count = State(0)
    
    override func render() -> AnyElement {
        Div {
            Text({ "Count: \(count.value)" })
        }
    }
}
```

### State Subscriptions

Manual state subscription (usually automatic):

```swift
let state = State(0)
let subscriptionId = UUID()

state.subscribe(subscriptionId) { id, value in
    print("State changed to: \(value)")
}

// Cleanup
state.unsubscribe(subscriptionId)
```

### Custom Elements

Create custom elements by conforming to the `Element` protocol:

```swift
public class CustomElement: Element {
    public let name = "custom"
    public let refId = UUID()
    public var stateSubscribers: [UUID: AnyState] = [:]
    public var children: [AnyElement] = []
    public var content: () -> [AnyElement]
    public var attributes: () -> DictValue
    public var _attributes: DictValue = [:]
    
    public init(
        attributes: @escaping () -> DictValue = {[:]},
        @ElementBuilder _ content: @escaping () -> [AnyElement]
    ) {
        self.content = content
        self.attributes = attributes
        let (attributes, children) = children()
        self.children = children
        self._attributes = attributes
    }
}
```

---

## Performance Considerations

### Efficient Updates

- Only changed attributes are updated in the DOM
- State subscriptions are automatically managed
- Elements are unmounted and cleaned up properly

### Best Practices

1. **Minimize state reads**: Cache state values if used multiple times
2. **Use specific states**: Break down large state objects
3. **Avoid unnecessary re-renders**: Use conditional rendering wisely
4. **Clean up subscriptions**: Elements automatically unsubscribe on unmount

---

## Debugging

### Debug Prints

The framework includes debug prints for:
- Element mounting/unmounting
- State changes
- Attribute updates
- ForEach operations

### Common Issues

1. **State not updating**: Ensure you're modifying `state.value`, not the state itself
2. **Multiple renders**: Check for circular state dependencies
3. **Memory leaks**: Ensure elements are properly unmounted

---

## Dependencies

- **JavaScriptKit**: Bridge between Swift and JavaScript
- **SwiftWasm**: Swift to WebAssembly compiler

---

## Future Roadmap

From the TODO list:
- [ ] Components system
- [ ] PhantomElement for If-Else (prevents parent re-renders)
- [ ] Additional convenience initializers
- [ ] More built-in elements (table, form elements, etc.)

---

## License

GPL-3.0 (for template modifications)
Projects using this framework can be closed source.

---

## Contributing

This is a template repository. Feel free to:
- Add new elements
- Improve the rendering system
- Enhance state management
- Add more examples

---

## Support

For issues and questions, please refer to the GitHub repository.
