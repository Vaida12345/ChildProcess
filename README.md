# ChildProcess

A Swift package for spawning and interacting with child processes and executing AppleScript on macOS.

## Overview

ChildProcess provides a modern, Swift 6–concurrent API over Foundation's `Process` and `NSAppleScript`. It handles pipe setup, process lifecycle, and result collection so you can focus on the command you want to run.

Two core capabilities:

- **`ChildProcess`** — spawn a subprocess by name or path, optionally interact with it via stdin/stdout/stderr, or use the one-shot `run` method to collect output.
- **`AppleScript`** — compile and execute AppleScript source on the `MainActor`, with strongly-typed result conversion via `ReturnType`.

All APIs are macOS-only (`macOS 13+`) and written for Swift 6 language mode with full `Sendable` conformance.

## Installation

Add this package to your project using Swift Package Manager.

```swift
// Package.swift
dependencies: [
    .package(url: "<package-url>", from: "0.4.1"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "ChildProcess", package: "ChildProcess"),
        ]
    ),
]
```

## Usage

### ChildProcess — one-shot execution

```swift
import ChildProcess

// Run a command by name (launched via /bin/zsh -c)
let result = try await ChildProcess.run(
    .name("ls"),
    arguments: ["-la"],
    workingDirectory: FilePath("/Users")
)
print(result.stdout ?? "")

// Run an executable by path
let result = try await ChildProcess.run(
    .path(FilePath("/usr/bin/which")),
    arguments: ["swift"]
)
```

Throws a `ChildProcessError` on non-zero exit:

```swift
do {
    let result = try await ChildProcess.run(.name("false"))
} catch let error as ChildProcess.ChildProcessError {
    print(error.terminationStatus) // 1
}
```

### ChildProcess — interactive subprocess

```swift
let process = try ChildProcess.makeProcess(.path(FilePath("/usr/bin/bc")))

// Write input
try process.stdin.write("1 + 1")

// Read output
let output = try process.stdout.readToEnd()
```

### Process control

```swift
process.pause()     // Suspend execution
process.resume()    // Resume after pause
process.terminate() // Request termination
```

### AppleScript

```swift
import ChildProcess

// Scalar return types
let count: Int = try await AppleScript.run(returning: .int, source: "return 42")
let name: String = try await AppleScript.run(source: "return \"Hello\"")

// List return types
let numbers: [Int] = try await AppleScript.run(
    returning: .list(of: .int),
    source: "return {1, 2, 3}"
)

// Error handling
do {
    let result: String = try await AppleScript.run(source: "bad syntax")
} catch AppleScript.ExecutionError.invalidScript {
    print("Could not compile")
} catch AppleScript.ExecutionError.executionFailed(let info) {
    print(info.message ?? "Unknown error")
}
```

> **Note:** `AppleScript.run` executes on the `MainActor` to prevent concurrency bugs. Set `NSAppleEventsUsageDescription` in `Info.plist` and, if sandboxed, the `com.apple.security.automation.apple-events` entitlement.

## Requirements

- macOS 13+
- Swift 6

## License

MIT
