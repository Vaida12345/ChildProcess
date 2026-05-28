import Testing
import System
import Foundation
@testable import ChildProcess

@Suite(.serialized)
struct ChildProcessTests {
    
    @Test func directReturn() async throws {
        let testDir = FilePath(URL(fileURLWithPath: #filePath).deletingLastPathComponent().path)
        let (stdout, stderr) = try await ChildProcess.run(
            .path("/bin/ls"),
            workingDirectory: testDir
        )

        #expect(stdout == "ChildProcessTests.swift\n")
        #expect(stderr == nil)
    }
    
    @Test func directReturnBuiltInCommand() async throws {
        let (stdout, stderr) = try await ChildProcess.run(.name("which"), arguments: ["ls"])
        
        #expect(stdout == "/bin/ls\n")
        #expect(stderr == nil)
    }
    
    @Test func inputOutput() async throws {
        let childProcess = try ChildProcess.makeProcess(.path("/usr/bin/bc"))

        var lines = childProcess.stdout.bytes.lines.makeAsyncIterator()
        try childProcess.stdin.write("1 + 1")
        let next = try await lines.next()?.trimmingCharacters(in: .whitespaces)
        #expect(next == "2")
    }
    
    @Test func appleScriptScalarReturnTypes() async throws {
        let int = try AppleScript.run(returning: .int, source: "return 42")
        let bool = try AppleScript.run(returning: .bool, source: "return true")
        let double = try AppleScript.run(returning: .double, source: "return 2.5")
        let string = try AppleScript.run(source: #"return "1234""#)
        
        #expect(int == 42)
        #expect(bool == true)
        #expect(double == 2.5)
        #expect(string == "1234")
    }
    
    @Test func appleScriptListReturnTypesFromScript() async throws {
        let ints = try AppleScript.run(returning: .list(of: .int), source: "return {1, 2, 3}")
        let bools = try AppleScript.run(returning: .list(of: .bool), source: "return {true, false, true}")
        let doubles = try AppleScript.run(returning: .list(of: .double), source: "return {1.25, 2.5, 5.0}")
        
        #expect(ints == [1, 2, 3])
        #expect(bools == [true, false, true])
        #expect(doubles == [1.25, 2.5, 5.0])
    }
    
    @Test func appleScriptListReturnTypesFromDescriptors() throws {
        let dataDescriptors = [
            NSAppleEventDescriptor(string: "alpha"),
            NSAppleEventDescriptor(string: "beta")
        ]
        let dates = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 1_000)
        ]
        let urls = [
            URL(fileURLWithPath: "/tmp/alpha"),
            URL(fileURLWithPath: "/tmp/beta")
        ]
        
        let data = try AppleScript.ReturnType<Array<Data>>.list(of: .data).getValue(makeList(dataDescriptors))
        let date = try AppleScript.ReturnType<Array<Date>>.list(of: .date).getValue(makeList(dates.map(NSAppleEventDescriptor.init(date:))))
        let fileURL = try AppleScript.ReturnType<Array<URL>>.list(of: .fileURL).getValue(makeList(urls.map(NSAppleEventDescriptor.init(fileURL:))))
        
        #expect(data == dataDescriptors.map(\.data))
        #expect(date == dates)
        #expect(fileURL == urls)
    }
    
    private func makeList(_ descriptors: [NSAppleEventDescriptor]) -> NSAppleEventDescriptor {
        let list = NSAppleEventDescriptor.list()
        
        for descriptor in descriptors {
            list.insert(descriptor, at: 0)
        }
        
        return list
    }
}
