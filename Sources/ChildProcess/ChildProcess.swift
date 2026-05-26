//
//  ChildProcess.swift
//  ChildProcess
//
//  Created by Vaida on 2026-05-06.
//

#if os(macOS)
import Foundation
import System


public final class ChildProcess: Sendable {
    
    /// The object that represents a ChildProcess of the current process.
    private let task: Process
    
    /// The one-way communications channel between related processes.
    private let standardInput: Pipe
    private let standardOutput: Pipe
    private let standardError: Pipe
    
    public var stdin: FileHandle {
        standardInput.fileHandleForWriting
    }
    
    public var stdout: FileHandle {
        standardOutput.fileHandleForReading
    }
    
    public var stderr: FileHandle {
        standardError.fileHandleForReading
    }
    
    
    /// Suspends execution of the receiver task.
    ///
    /// Multiple ``pause()`` messages can be sent, but they must be balanced with an equal number of ``resume()`` messages before the task resumes execution.
    public func pause() {
        task.suspend()
    }
    
    /// Resumes execution of a suspended task.
    ///
    /// Multiple ``pause()`` messages can be sent, but they must be balanced with an equal number of ``resume()`` messages before the task resumes execution.
    public func resume() {
        task.resume()
    }
    
    /// Requests the managed process to terminate if it is currently running.
    public func terminate() {
        guard task.isRunning else { return }
        self.task.terminate()
    }
    
    
    init(task: Process) throws {
        self.task = task
        
        self.standardInput = Pipe()
        self.standardError = Pipe()
        self.standardOutput = Pipe()
        
        self.task.standardInput = standardInput
        self.task.standardOutput = standardOutput
        self.task.standardError = standardError
        
        try task.run()
        
        try? self.standardInput.fileHandleForReading.close()
        try? self.standardOutput.fileHandleForWriting.close()
        try? self.standardError.fileHandleForWriting.close()
    }
    
    deinit {
        self.terminate()
        
        try? self.standardInput.fileHandleForWriting.close()
        
        try? self.standardOutput.fileHandleForReading.close()
        
        try? self.standardError.fileHandleForReading.close()
    }
    
    
    /// Spawn a child process and returns immediately.
    public static func makeProcess(
        _ origin: Origin,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) throws -> ChildProcess {
        let task = Process()
        switch origin {
        case .name(let string):
            task.executableURL = URL(filePath: "/bin/zsh")
            task.arguments = ["-c", string + " " + arguments.joined(separator: " ")]
        case .path(let filePath):
            task.executableURL = URL(filePath: filePath)
            task.arguments = arguments
        }
        task.currentDirectoryURL = workingDirectory.flatMap({ URL(filePath: $0) })
        task.environment = environment
        
        return try ChildProcess(task: task)
    }
    
    /// Run, wait for exit, and collect stderr and stdout as `String`.
    public static func run(
        _ origin: Origin,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) async throws -> (stdout: String?, stderr: String?) {
        let childProcess = try ChildProcess.makeProcess(
            origin,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )

        return try await withCheckedThrowingContinuation { continuation in
            childProcess.task.terminationHandler = { task in
                guard task.terminationStatus == 0 else {
                    continuation.resume(
                        throwing: ChildProcessError(terminationStatus: task.terminationStatus)
                    )
                    return
                }

                func read(from fileHandle: FileHandle) -> String? {
                    guard let data = try? fileHandle.readToEnd() else { return nil }
                    return String(data: data, encoding: .utf8)
                }

                let stdoutStr = read(from: childProcess.stdout)
                let stderrStr = read(from: childProcess.stderr)
                continuation.resume(returning: (stdoutStr, stderrStr))
            }
        }
    }
    
    public struct ChildProcessError: Error, CustomStringConvertible, Equatable {
        public let terminationStatus: Int32

        public var description: String {
            "Process exited with status \(terminationStatus)"
        }
    }
    
    public enum Origin {
        case name(String)
        case path(FilePath)
    }
    
}

#endif
