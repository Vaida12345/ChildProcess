//
//  AppleScript.swift
//  ChildProcess
//
//  Created by Vaida on 2026-05-24.
//

#if os(macOS)
import Foundation


/// A namespace for compiling and executing AppleScript source from Swift.
public enum AppleScript {
    
    /// Executes AppleScript source and converts the returned descriptor into the requested Swift value.
    ///
    /// - Parameters:
    ///   - returning: The return type adapter used to read the Apple event descriptor.
    ///   - source: The AppleScript source to execute.
    ///
    /// - Returns: The value extracted from the script result.
    ///
    /// - Warning: You must not call this method in parallel. However, this package cannot ensure that due to possible conflicts between old API and swift concurrency.
    ///
    /// - Throws: An ``ExecutionError`` when the source is invalid, execution fails, or the result cannot be converted.
    public static func run<T>(
        returning: ReturnType<T> = .string,
        source: String
    ) throws(ExecutionError) -> T {
        guard let appleScript = NSAppleScript(source: source) else { throw ExecutionError.invalidScript }
        
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        
        if let error = error { throw .executionFailed(ScriptErrorInfo(error)) }
        
        return try returning.getValue(result)
    }
    
    /// Error information extracted from an AppleScript execution failure.
    public struct ScriptErrorInfo: Sendable {
        /// The error message from AppleScript.
        public let message: String?
        /// The error number from AppleScript.
        public let number: Int?
        /// A brief error message from AppleScript.
        public let briefMessage: String?
        /// The application name where the error occurred.
        public let appName: String?

        init(_ dictionary: NSDictionary) {
            message = dictionary[NSAppleScript.errorMessage] as? String
            number = dictionary[NSAppleScript.errorNumber] as? Int
            briefMessage = dictionary[NSAppleScript.errorBriefMessage] as? String
            appName = dictionary[NSAppleScript.errorAppName] as? String
        }
    }

    /// An error that can occur while compiling, executing, or reading the result of an AppleScript.
    public enum ExecutionError: Error, Sendable {
        /// The AppleScript source could not be compiled.
        case invalidScript

        /// AppleScript execution failed and returned an error dictionary.
        case executionFailed(ScriptErrorInfo)
        
        /// The returned descriptor did not contain a value for the requested type.
        case noValue
        
        /// A list descriptor did not contain an item at the expected zero-based index.
        case indexOutOfBounds(Int)
    }
}


extension AppleScript {
    
    /// A converter that reads an Apple event descriptor as a specific Swift value.
    public struct ReturnType<Value>: Sendable {
        let getValue: @Sendable (_ descriptor: NSAppleEventDescriptor) throws(ExecutionError) -> Value
        
        init(getValue: @Sendable @escaping (_: NSAppleEventDescriptor) throws(ExecutionError) -> Value) {
            self.getValue = getValue
        }
    }
    
    nonisolated static func _getReturnTypeList<T>(of returnType: ReturnType<T>, descriptor: NSAppleEventDescriptor) throws(ExecutionError) -> [T] {
        let count = descriptor.numberOfItems
        
        return try Array(unsafeUninitializedCapacity: count) { (buffer, initializedCount) throws(ExecutionError) in
            while initializedCount < count {
                let descriptorIndex = initializedCount + 1
                guard let value = descriptor.atIndex(descriptorIndex) else { throw .indexOutOfBounds(initializedCount) }
                buffer.initializeElement(at: initializedCount, to: try returnType.getValue(value))
                
                initializedCount += 1
            }
        }
    }
    
}


// MARK: - Values
extension AppleScript.ReturnType where Value == Int {
    
    /// Reads an AppleScript integer result as an `Int`.
    public static let int = AppleScript.ReturnType<Int> { descriptor in
        Int(descriptor.int32Value)
    }
    
}

extension AppleScript.ReturnType where Value == Data {
    
    /// Reads an Apple event descriptor as `Data`.
    public static let data = AppleScript.ReturnType<Data> { descriptor in
        descriptor.data
    }
    
}

extension AppleScript.ReturnType where Value == Bool {
    
    /// Reads an AppleScript boolean result as a `Bool`.
    public static let bool = AppleScript.ReturnType<Bool> { descriptor in
        descriptor.booleanValue
    }
    
}

extension AppleScript.ReturnType where Value == Double {
    
    /// Reads an AppleScript real number result as a `Double`.
    public static let double = AppleScript.ReturnType<Double> { descriptor in
        descriptor.doubleValue
    }
    
}

extension AppleScript.ReturnType where Value == Date {
    
    /// Reads an AppleScript date result as a `Date`.
    public static let date = AppleScript.ReturnType<Date> { (descriptor) throws(AppleScript.ExecutionError) -> Date in
        guard let date = descriptor.dateValue else {
            throw .noValue
        }
        return date
    }
    
}

extension AppleScript.ReturnType where Value == URL {
    
    /// Reads an AppleScript file result as a file `URL`.
    public static let fileURL = AppleScript.ReturnType<URL> { (descriptor) throws(AppleScript.ExecutionError) -> URL in
        guard let url = descriptor.fileURLValue else {
            throw .noValue
        }
        return url
    }
    
}

extension AppleScript.ReturnType where Value == String {
    
    /// Reads an AppleScript result as a utf8 `String`.
    public static let string = AppleScript.ReturnType<String> { (descriptor) throws(AppleScript.ExecutionError) -> String in
        guard let string = descriptor.stringValue else {
            throw .noValue
        }
        return string
    }
    
}

// MARK: - Lists

extension AppleScript.ReturnType where Value == Array<Int> {
    
    /// Reads an AppleScript list of integers as `[Int]`.
    public static func list(of type: AppleScript.ReturnType<Int>) -> AppleScript.ReturnType<Array<Int>> {
        AppleScript.ReturnType<Array<Int>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<Int> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
}

extension AppleScript.ReturnType where Value == Array<Data> {
    
    /// Reads an AppleScript list of descriptors as `[Data]`.
    public static func list(of type: AppleScript.ReturnType<Data>) -> AppleScript.ReturnType<Array<Data>> {
        AppleScript.ReturnType<Array<Data>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<Data> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}

extension AppleScript.ReturnType where Value == Array<Bool> {
    
    /// Reads an AppleScript list of booleans as `[Bool]`.
    public static func list(of type: AppleScript.ReturnType<Bool>) -> AppleScript.ReturnType<Array<Bool>> {
        AppleScript.ReturnType<Array<Bool>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<Bool> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}

extension AppleScript.ReturnType where Value == Array<Double> {
    
    /// Reads an AppleScript list of real numbers as `[Double]`.
    public static func list(of type: AppleScript.ReturnType<Double>) -> AppleScript.ReturnType<Array<Double>> {
        AppleScript.ReturnType<Array<Double>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<Double> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}

extension AppleScript.ReturnType where Value == Array<Date> {
    
    /// Reads an AppleScript list of dates as `[Date]`.
    public static func list(of type: AppleScript.ReturnType<Date>) -> AppleScript.ReturnType<Array<Date>> {
        AppleScript.ReturnType<Array<Date>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<Date> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}

extension AppleScript.ReturnType where Value == Array<URL> {
    
    /// Reads an AppleScript list of file results as `[URL]`.
    public static func list(of type: AppleScript.ReturnType<URL>) -> AppleScript.ReturnType<Array<URL>> {
        AppleScript.ReturnType<Array<URL>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<URL> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}


extension AppleScript.ReturnType where Value == Array<String> {

    /// Reads an AppleScript list of strings as `[String]`.
    public static func list(of type: AppleScript.ReturnType<String>) -> AppleScript.ReturnType<Array<String>> {
        AppleScript.ReturnType<Array<String>> { (descriptor) throws(AppleScript.ExecutionError) -> Array<String> in
            try AppleScript._getReturnTypeList(of: type, descriptor: descriptor)
        }
    }
    
}

#endif
