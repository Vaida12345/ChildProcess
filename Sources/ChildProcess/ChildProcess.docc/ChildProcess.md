# ChildProcess

A Swift package for spawning and interacting with child processes and executing AppleScript on macOS.

## Overview

ChildProcess provides a modern, Swift 6–concurrent API over Foundation's `Process` and `NSAppleScript`. It handles pipe setup, process lifecycle, and result collection so you can focus on the command you want to run.

Two core capabilities:

- **``ChildProcess``** — spawn a subprocess by name or path, optionally interact with it via stdin/stdout/stderr, or use the one-shot `run` method to collect output.
- **``AppleScript``** — compile and execute AppleScript source, with strongly-typed result conversion via ``AppleScript/ReturnType``.

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

## Topics

### ChildProcess

- ``ChildProcess``
- ``ChildProcess/makeProcess(_:arguments:workingDirectory:environment:)``
- ``ChildProcess/run(_:arguments:workingDirectory:environment:)``
- ``ChildProcess/pause()``
- ``ChildProcess/resume()``
- ``ChildProcess/terminate()``
- ``ChildProcess/stdin``
- ``ChildProcess/stdout``
- ``ChildProcess/stderr``
- ``ChildProcess/Origin``
- ``ChildProcess/ChildProcessError``

### AppleScript

- ``AppleScript``
- ``AppleScript/run(returning:source:)``
- ``AppleScript/ReturnType``
- ``AppleScript/ExecutionError``
- ``AppleScript/ScriptErrorInfo``

### Convenience Extensions

- ``Swift/FileHandle/write(_:terminator:)``

### Articles

- <doc:ChildProcess-Usage>
- <doc:AppleScript-Usage>
