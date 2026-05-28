# Using ChildProcess

``ChildProcess`` is the main type for launching and controlling a subprocess.

## One-shot execution

Use ``ChildProcess/run(_:arguments:workingDirectory:environment:)`` when you want to run a command, wait for it to finish, and collect its output. It throws a ``ChildProcess/ChildProcessError`` if the process exits with a non-zero status.

```swift
// Run a command by name
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

Throwing a ``ChildProcess/ChildProcessError`` on failure:

```swift
do {
    let result = try await ChildProcess.run(.name("false"))
} catch let error as ChildProcess.ChildProcessError {
    print(error.terminationStatus) // 1
    print(error) // "Process exited with status 1"
}
```

## Interactive subprocess

Use ``ChildProcess/makeProcess(_:arguments:workingDirectory:environment:)`` when you need to interact with a long-running subprocess. This method returns immediately after spawning, giving you access to ``ChildProcess/stdin``, ``ChildProcess/stdout``, and ``ChildProcess/stderr``.

```swift
let process = try ChildProcess.makeProcess(.path(FilePath("/usr/bin/bc")))

// Write input to the subprocess
try process.stdin.write("1 + 1")

// Read output line by line
let output = try process.stdout.readToEnd()
print(String(data: output!, encoding: .utf8)!) // "2"
```

## Process control

You can pause, resume, and terminate a running subprocess:

```swift
process.pause()     // Suspend execution
process.resume()    // Resume after pause
process.terminate() // Request termination
```

## Specifying the executable

Use ``ChildProcess/Origin`` to specify how the subprocess should be launched:

- ``ChildProcess/Origin/name(_:)`` — launches via `/bin/zsh -c`, which resolves the command from `PATH` and supports shell syntax.
- ``ChildProcess/Origin/path(_:)`` — launches an executable directly at the given file system path.

```swift
// Via shell (resolves PATH, supports pipes, redirects, etc.)
ChildProcess.run(.name("echo hello"))

// Via direct path (no shell interpretation)
ChildProcess.run(.path(FilePath("/bin/echo")), arguments: ["hello"])
```
