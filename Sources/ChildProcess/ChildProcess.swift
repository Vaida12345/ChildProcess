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
        self.task.terminate()
        
        try? self.standardInput.fileHandleForReading.close()
        try? self.standardInput.fileHandleForWriting.close()
        
        try? self.standardOutput.fileHandleForReading.close()
        try? self.standardOutput.fileHandleForWriting.close()
        
        try? self.standardError.fileHandleForReading.close()
        try? self.standardError.fileHandleForWriting.close()
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
    }
    
    deinit {
        self.terminate()
    }
    
    
    /// Spawn a child process and returns immediately.
    public static func makeProcess(
        _ path: FilePath,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) throws -> ChildProcess {
        let task = Process()
        task.executableURL = URL(filePath: path)
        task.arguments = arguments
        task.currentDirectoryURL = workingDirectory.flatMap({ URL(filePath: $0) })
        task.environment = environment
        
        return try ChildProcess(task: task)
    }
    
    /// Run, wait for exit, and collect stderr and stdout as `String`.
    public static func run(
        _ path: FilePath,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) async throws -> (stdout: String?, stderr: String?) {
        let ChildProcess = try ChildProcess.makeProcess(
            path,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )
        ChildProcess.task.waitUntilExit()
        guard ChildProcess.task.terminationStatus == 0 else {
            throw ChildProcessError(terminationStatus: ChildProcess.task.terminationStatus)
        }
        
        func read(from pipe: Pipe) -> String? {
            guard let data = try? pipe.fileHandleForReading.readToEnd() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        
        return (read(from: ChildProcess.standardOutput), read(from: ChildProcess.standardError))
    }
    
    public struct ChildProcessError: Error {
        public let terminationStatus: Int32
    }
    
}

#endif
