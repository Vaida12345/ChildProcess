# Using AppleScript

``AppleScript`` is a namespace for compiling and executing AppleScript source code from Swift, with strongly-typed result conversion.

## Basic execution

Call ``AppleScript/run(returning:source:)`` with AppleScript source. It compiles the script, executes it on the `MainActor`, and converts the returned Apple event descriptor into the Swift type you request.

```swift
import ChildProcess

// Execute a simple script and get a string result
let name: String = try await AppleScript.run(source: "return \"Hello from AppleScript\"")

// Get an integer result
let count: Int = try await AppleScript.run(returning: .int, source: "return 42")

// Get a boolean result
let ok: Bool = try await AppleScript.run(returning: .bool, source: "return true")
```

## Scalar return types

``AppleScript/ReturnType`` provides static properties for common scalar types:

| Property | Swift type |
|----------|------------|
| `.string` | `String` |
| `.int`    | `Int`    |
| `.double` | `Double` |
| `.bool`   | `Bool`   |
| `.date`   | `Date`   |
| `.fileURL`| `URL`    |
| `.data`   | `Data`   |

```swift
let today: Date = try await AppleScript.run(
    returning: .date,
    source: "return current date"
)

let path: URL = try await AppleScript.run(
    returning: .fileURL,
    source: "return path to desktop"
)
```

## List return types

Use ``AppleScript/ReturnType/list(of:)`` to read AppleScript lists:

```swift
let numbers: [Int] = try await AppleScript.run(
    returning: .list(of: .int),
    source: "return {1, 2, 3, 4, 5}"
)

let names: [String] = try await AppleScript.run(
    returning: .list(of: .string),
    source: "return {\"Alice\", \"Bob\", \"Charlie\"}"
)
```

## Error handling

``AppleScript/run(returning:source:)`` throws ``AppleScript/ExecutionError``, which has four cases:

```swift
do {
    let result: String = try await AppleScript.run(source: "invalid syntax???")
} catch .invalidScript {
    // The source could not be compiled
} catch .executionFailed(let info) {
    // The script compiled but failed at runtime
    print(info.message ?? "Unknown error")
    print(info.number ?? -1)
} catch .noValue {
    // The descriptor didn't contain a value for the requested type
} catch .indexOutOfBounds(let index) {
    // A list descriptor was missing an item at the given index
}
```

## Platform requirements

- Set `NSAppleEventsUsageDescription` in your app's `Info.plist` to describe why you need Apple Events access.
- If your app uses the App Sandbox, include the `com.apple.security.automation.apple-events` entitlement.

> Note: ``AppleScript/run(returning:source:)`` executes on the `MainActor` to prevent concurrency bugs with the underlying `NSAppleScript` API.
