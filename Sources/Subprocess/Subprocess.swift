//
//  Subprocess.swift
//  Subprocess
//
//  Created by Vaida on 2026-05-06.
//

#if os(macOS)
import Foundation
import System


public final class Subprocess: Sendable {
    
    /// The object that represents a subprocess of the current process.
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
        task.terminate()
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
        self.task.terminate()
    }
    
    
    /// Spawn a child process and returns immediately.
    public static func makeSubprocess(
        _ path: FilePath,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) throws -> Subprocess {
        let task = Process()
        task.executableURL = URL(filePath: path)
        task.arguments = arguments
        task.currentDirectoryURL = workingDirectory.flatMap({ URL(filePath: $0) })
        task.environment = environment
        
        return try Subprocess(task: task)
    }
    
    /// Run, wait for exit, and collect stderr and stdout as `String`.
    public static func run(
        _ path: FilePath,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil,
        environment: [String : String]? = nil
    ) async throws -> (stdout: String?, stderr: String?) {
        let subprocess = try Subprocess.makeSubprocess(
            path,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )
        subprocess.task.waitUntilExit()
        guard subprocess.task.terminationStatus == 0 else {
            throw SubprocessError(terminationStatus: subprocess.task.terminationStatus)
        }
        
        func read(from pipe: Pipe) -> String? {
            guard let data = try? pipe.fileHandleForReading.readToEnd() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        
        return (read(from: subprocess.standardOutput), read(from: subprocess.standardError))
    }
    
    public struct SubprocessError: Error {
        public let terminationStatus: Int32
    }
    
}

#endif
