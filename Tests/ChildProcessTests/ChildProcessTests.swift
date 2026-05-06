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
}
