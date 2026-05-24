import Testing
import Foundation
@testable import ChildProcess

@Suite
struct ChildProcessTests {
    
    @Test func directReturn() async throws {
        let (stdout, stderr) = try await ChildProcess.run(
            .path("/bin/ls"),
            workingDirectory: "/Users/vaida/Library/Mobile Documents/com~apple~CloudDocs/DataBase/Projects/Packages/ChildProcess/Tests"
        )

        #expect(stdout == "ChildProcessTests\n")
        #expect(stderr == nil)
    }
    
    @Test func directReturnBuiltInCommand() async throws {
        let (stdout, stderr) = try await ChildProcess.run(.name("which"), arguments: ["ls"])
        
        #expect(stdout == "/bin/ls\n")
        #expect(stderr == nil)
    }
    
    @Test func inputOutput() async throws {
        let ChildProcess = try ChildProcess.makeProcess(.path("/opt/homebrew/bin/calc"))
        
        var lines = ChildProcess.stdout.bytes.lines.makeAsyncIterator()
        try ChildProcess.stdin.write("1 + 1")
        let next = try await lines.next()?.trimmingCharacters(in: .whitespaces)
        #expect(next == "2")
    }
    
    @Test func appleScriptScalarReturnTypes() async throws {
        let int = try await AppleScript.run(returning: .int, source: "return 42")
        let bool = try await AppleScript.run(returning: .bool, source: "return true")
        let double = try await AppleScript.run(returning: .double, source: "return 2.5")
        
        #expect(int == 42)
        #expect(bool == true)
        #expect(double == 2.5)
    }
    
    @Test func appleScriptListReturnTypesFromScript() async throws {
        let ints = try await AppleScript.run(returning: .list(of: .int), source: "return {1, 2, 3}")
        let bools = try await AppleScript.run(returning: .list(of: .bool), source: "return {true, false, true}")
        let doubles = try await AppleScript.run(returning: .list(of: .double), source: "return {1.25, 2.5, 5.0}")
        
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
